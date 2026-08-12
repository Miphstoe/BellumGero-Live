#!/usr/bin/env python3
"""Desired-state batch composition for Bellum Gero World Builder WBP V3 extensions.

The existing batch publisher remains the owner of snapshots, root/cell OIDs,
project-specific shared building IFFs, server-template Lua registration, TRE-v5
packing, dependency hashing, and transactional deployment. This layer adds a
project dependency graph and composes EXTERNAL_INTERIOR records into the parent
structure's already-generated ILF.
"""

from __future__ import annotations

import dataclasses
import hashlib
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

import worldbuilder_project_extensions as project_ext


@dataclass
class ExtensionContribution:
    contributor_publish_id: str
    target_publish_id: str
    target_structure_local_id: int
    interior: object

    def manifest_dict(self) -> dict:
        data = dataclasses.asdict(self.interior)
        return {
            "contributor_publish_id": self.contributor_publish_id,
            "target_publish_id": self.target_publish_id,
            "target_structure_local_id": self.target_structure_local_id,
            "interior": data,
        }


@dataclass
class ExtensionContext:
    approved_by_id: Dict[str, object]
    dependencies: Dict[str, Set[str]] = field(default_factory=dict)
    contributions: Dict[Tuple[str, int], List[ExtensionContribution]] = field(default_factory=dict)

    def relationship_manifest(self) -> List[dict]:
        rows: List[dict] = []
        for child in sorted(self.dependencies):
            project = self.approved_by_id[child].project
            for extension in sorted(
                getattr(project, "extensions", []),
                key=lambda value: (value.parent_publish_id, value.parent_structure_local_id),
            ):
                rows.append(
                    {
                        "child_publish_id": child,
                        "parent_publish_id": extension.parent_publish_id,
                        "parent_structure_local_id": extension.parent_structure_local_id,
                    }
                )
        return rows


_ACTIVE_CONTEXT: Optional[ExtensionContext] = None


def _canonical_json_hash(payload: dict) -> str:
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def _ensure_project_fields(project) -> None:
    project_ext._ensure_extension_fields(project)


def build_extension_context(wb, approved: Sequence[object]) -> ExtensionContext:
    approved_by_id = {entry.publish_id: entry for entry in approved}
    dependencies: Dict[str, Set[str]] = {entry.publish_id: set() for entry in approved}
    contributions: Dict[Tuple[str, int], List[ExtensionContribution]] = {}

    for entry in approved:
        child_id = entry.publish_id
        project = entry.project
        _ensure_project_fields(project)

        declared = {
            (extension.parent_publish_id, int(extension.parent_structure_local_id))
            for extension in project.extensions
        }

        for extension in project.extensions:
            parent_id = extension.parent_publish_id
            structure_id = int(extension.parent_structure_local_id)

            if parent_id == child_id:
                raise wb.WorldBuilderError(
                    f"World Builder extension cycle: project {child_id!r} cannot EXTEND itself"
                )
            parent = approved_by_id.get(parent_id)
            if parent is None:
                raise wb.WorldBuilderError(
                    f"Project {child_id!r} EXTENDS {parent_id!r} / Structure #{structure_id}, "
                    "but that parent is not enabled in the approved publish set. "
                    "Publish/enable the parent or remove the dependency before baking."
                )
            if parent.project.planet != project.planet:
                raise wb.WorldBuilderError(
                    f"Project {child_id!r} is on {project.planet!r} but EXTENDS parent {parent_id!r} "
                    f"on {parent.project.planet!r}. Cross-planet structure extensions are not valid."
                )

            parent_structures = {
                int(structure.local_id): structure
                for structure in parent.project.structures
            }
            if structure_id not in parent_structures:
                raise wb.WorldBuilderError(
                    f"Project {child_id!r} EXTENDS {parent_id!r} / Structure #{structure_id}, "
                    "but that STRUCTURE record no longer exists in the parent WBP."
                )

            dependencies[child_id].add(parent_id)

        for interior in project.external_interiors:
            target = (interior.parent_publish_id, int(interior.parent_structure_local_id))
            if target not in declared:
                # Normally caught by WBP validation. Keep a graph-level assertion so
                # hand-built Project instances cannot bypass the dependency contract.
                raise wb.WorldBuilderError(
                    f"Project {child_id!r} EXTERNAL_INTERIOR #{interior.local_id} targets "
                    f"{target[0]!r} / Structure #{target[1]} without a matching EXTENDS record"
                )
            contributions.setdefault(target, []).append(
                ExtensionContribution(
                    contributor_publish_id=child_id,
                    target_publish_id=target[0],
                    target_structure_local_id=target[1],
                    interior=interior,
                )
            )

    # Cycles are invalid even when the current projects happen to contribute no
    # objects yet. The relationship itself is durable desired-state dependency.
    state: Dict[str, int] = {publish_id: 0 for publish_id in approved_by_id}
    stack: List[str] = []

    def visit(node: str) -> None:
        state[node] = 1
        stack.append(node)
        for parent in sorted(dependencies.get(node, ())):
            if state[parent] == 0:
                visit(parent)
            elif state[parent] == 1:
                start = stack.index(parent) if parent in stack else 0
                cycle = stack[start:] + [parent]
                raise wb.WorldBuilderError(
                    "World Builder extension dependency cycle: " + " -> ".join(cycle)
                )
        stack.pop()
        state[node] = 2

    for node in sorted(approved_by_id):
        if state[node] == 0:
            visit(node)

    # Deterministic final ILF contribution order: contributor publish ID, then
    # contributor-local object ID. Parent-local INTERIOR records are already
    # emitted first by the proven V2 baker and are intentionally not reordered.
    for key in contributions:
        contributions[key].sort(
            key=lambda row: (row.contributor_publish_id, int(row.interior.local_id))
        )

    return ExtensionContext(
        approved_by_id=approved_by_id,
        dependencies=dependencies,
        contributions=contributions,
    )


def dependents_for(context: ExtensionContext, parent_publish_id: str) -> List[str]:
    return sorted(
        child
        for child, parents in context.dependencies.items()
        if parent_publish_id in parents
    )


def _compose_for_project(wb, resolver, publish_id: str, replacements: dict, bake_result) -> None:
    context = _ACTIVE_CONTEXT
    if context is None:
        return

    all_meta: List[dict] = []
    for structure in bake_result.structures:
        key = (publish_id, int(structure.local_id))
        rows = context.contributions.get(key, [])
        if not rows:
            continue

        source_iff = resolver.read(structure.source_shared_template)
        portal_path = wb.normalize_archive_path(
            wb.read_string_param(source_iff, "portalLayoutFilename")
        )
        if not portal_path:
            raise wb.WorldBuilderError(
                f"Extension target {publish_id} / Structure #{structure.local_id} has no portal layout"
            )
        portal = wb.parse_portal_layout(resolver.read(portal_path), portal_path)

        nodes: List[bytes] = []
        for row in rows:
            interior = row.interior
            if interior.cell_number <= 0 or interior.cell_number > portal.cell_count:
                raise wb.WorldBuilderError(
                    f"Project {row.contributor_publish_id!r} EXTERNAL_INTERIOR #{interior.local_id}: "
                    f"Cell {interior.cell_number} is invalid for parent {publish_id!r} / "
                    f"Structure #{structure.local_id} (portal cells: {portal.cell_count})"
                )
            portal_room = portal.rooms[interior.cell_number]
            if interior.room_name != portal_room:
                raise wb.WorldBuilderError(
                    f"Project {row.contributor_publish_id!r} EXTERNAL_INTERIOR #{interior.local_id}: "
                    f"saved room {interior.room_name!r} does not exactly match parent {publish_id!r} / "
                    f"Structure #{structure.local_id} Cell {interior.cell_number} room {portal_room!r}. "
                    "WBP V3 external placements require durable Cell + room identity; refusing to silently relocate the decoration."
                )
            nodes.append(wb.build_ilf_node(interior, portal_room))
            all_meta.append(row.manifest_dict())

        custom_path = wb.normalize_archive_path(structure.custom_interior_layout)
        current = replacements.get(custom_path)
        if current is None:
            # Existing baker uses normalized lower-case generated paths, but keep
            # one exact-key fallback for safety if that ever changes.
            current = replacements.get(structure.custom_interior_layout)
        if current is None:
            raise wb.WorldBuilderError(
                f"Internal World Builder error: generated parent ILF missing for {publish_id} / Structure #{structure.local_id}"
            )

        composed = wb.append_ilf_nodes(
            current,
            nodes,
            structure.custom_interior_layout + " [cross-project extensions]",
        )
        replacements[custom_path] = composed

        # Keep PublishedStructure.interior_local_ids semantically local to the
        # parent WBP. The batch validator wrapper accounts for external nodes
        # separately so contributor-local IDs never masquerade as parent IDs.

    if all_meta:
        bake_result.external_contributions = all_meta


def _manifest_publish_set_fresh(batch, config_path: Path, manifest: dict) -> None:
    config = batch.wb.load_config(config_path)
    publish_set_path = batch._config_required_path(config, config_path, "publish_set")
    current = batch.load_publish_set(publish_set_path)
    build_extension_context(batch.wb, current)  # revalidate graph at deployment time

    current_by_id = {entry.publish_id: entry for entry in current}
    candidate_by_id = {
        str(row.get("id")): row
        for row in manifest.get("projects", [])
        if isinstance(row, dict) and row.get("id")
    }

    if set(current_by_id) != set(candidate_by_id):
        added = sorted(set(current_by_id) - set(candidate_by_id))
        removed = sorted(set(candidate_by_id) - set(current_by_id))
        details = []
        if added:
            details.append("now enabled: " + ", ".join(added))
        if removed:
            details.append("no longer enabled: " + ", ".join(removed))
        raise batch.wb.WorldBuilderError(
            "The validated World Builder candidate is stale because the approved publish set changed after bake ("
            + "; ".join(details)
            + "). Run 'wb bake' again."
        )

    changed: List[str] = []
    for publish_id in sorted(current_by_id):
        current_sha = current_by_id[publish_id].wbp_sha256
        expected_sha = candidate_by_id[publish_id].get("wbp_sha256")
        if not expected_sha or current_sha != expected_sha:
            changed.append(publish_id)
    if changed:
        raise batch.wb.WorldBuilderError(
            "The validated World Builder candidate is stale because WBP source project(s) changed after bake: "
            + ", ".join(changed)
            + ". Run 'wb bake' again before deployment."
        )


def install(batch) -> None:
    """Install V3 dependency/composition behavior into worldbuilder_batch."""
    if getattr(batch, "_bellum_batch_extensions_v3_installed", False):
        return

    wb = batch.wb
    project_ext.install(wb)

    original_build_candidate = batch.build_candidate
    original_bake_snapshot_v2 = wb.bake_snapshot_v2
    original_project_fingerprint = batch._project_fingerprint
    original_project_manifest_entry = batch._project_manifest_entry
    original_validate_project_assets = batch.validate_project_assets
    original_deploy_candidate = batch.deploy_candidate

    def bake_snapshot_v2(*args, **kwargs):
        if len(args) >= 3:
            project = args[1]
            resolver = args[2]
        else:
            project = kwargs["project"]
            resolver = kwargs["resolver"]

        publish_id = kwargs.get("publish_id") or wb.project_slug(project.name)
        baked_snapshot, replacements, result = original_bake_snapshot_v2(*args, **kwargs)
        _compose_for_project(wb, resolver, publish_id, replacements, result)
        return baked_snapshot, replacements, result

    def validate_project_assets(finished, resolver, result) -> None:
        received = getattr(result.bake_result, "external_contributions", [])
        if not received:
            return original_validate_project_assets(finished, resolver, result)

        for structure in result.bake_result.structures:
            root_template = structure.custom_shared_template
            custom_iff = finished.extract(root_template)
            if wb.normalize_archive_path(wb.read_string_param(custom_iff, "interiorLayoutFileName")) != wb.normalize_archive_path(structure.custom_interior_layout):
                raise wb.WorldBuilderError(
                    f"Candidate project {result.approved.publish_id} STRUCTURE #{structure.local_id} shared IFF does not point at its custom ILF"
                )
            if wb.normalize_archive_path(wb.read_string_param(custom_iff, "portalLayoutFilename")) != wb.normalize_archive_path(structure.source_portal_layout):
                raise wb.WorldBuilderError(
                    f"Candidate project {result.approved.publish_id} STRUCTURE #{structure.local_id} portal layout changed"
                )

            final_nodes = wb.parse_ilf(
                finished.extract(structure.custom_interior_layout),
                structure.custom_interior_layout,
            )
            source_count = 0
            if structure.source_interior_layout != "<empty>":
                try:
                    source_count = len(
                        wb.parse_ilf(
                            resolver.read(structure.source_interior_layout),
                            structure.source_interior_layout,
                        )
                    )
                except wb.WorldBuilderError:
                    source_count = 0

            external_count = sum(
                1
                for row in received
                if int(row.get("target_structure_local_id", -1)) == int(structure.local_id)
            )
            expected_count = source_count + len(structure.interior_local_ids) + external_count
            if len(final_nodes) != expected_count:
                raise wb.WorldBuilderError(
                    f"Candidate project {result.approved.publish_id} STRUCTURE #{structure.local_id} ILF node count mismatch: "
                    f"{len(final_nodes)} != {source_count}+{len(structure.interior_local_ids)}+{external_count} external"
                )

    def project_fingerprint(result) -> str:
        legacy = original_project_fingerprint(result)
        project = result.approved.project
        _ensure_project_fields(project)
        received = getattr(result.bake_result, "external_contributions", [])
        if not project.extensions and not project.external_interiors and not received:
            # Critical compatibility promise: untouched V1/V2 projects retain
            # the exact pre-V1.9.8 fingerprint algorithm.
            return legacy
        payload = {
            "legacy_fingerprint": legacy,
            "extensions": [dataclasses.asdict(value) for value in project.extensions],
            "external_interiors": [dataclasses.asdict(value) for value in project.external_interiors],
            "received_external_contributions": received,
        }
        return _canonical_json_hash(payload)

    def project_manifest_entry(result) -> dict:
        entry = original_project_manifest_entry(result)
        project = result.approved.project
        _ensure_project_fields(project)
        if project.version >= project_ext.WBP_EXTENSION_VERSION or project.extensions or project.external_interiors:
            entry["counts"]["extensions"] = len(project.extensions)
            entry["counts"]["external_interiors"] = len(project.external_interiors)
            entry["extensions"] = [dataclasses.asdict(value) for value in project.extensions]
            entry["external_interiors"] = [dataclasses.asdict(value) for value in project.external_interiors]
        received = getattr(result.bake_result, "external_contributions", [])
        if received:
            entry["received_external_contributions"] = received
        return entry

    def build_candidate(config_path: Path, default_game_type=None) -> dict:
        global _ACTIVE_CONTEXT
        config_path = Path(config_path).resolve()
        config = wb.load_config(config_path)
        publish_set_path = batch._config_required_path(config, config_path, "publish_set")
        approved = batch.load_publish_set(publish_set_path)
        context = build_extension_context(wb, approved)

        previous_context = _ACTIVE_CONTEXT
        _ACTIVE_CONTEXT = context
        try:
            manifest = original_build_candidate(config_path, default_game_type)
        finally:
            _ACTIVE_CONTEXT = previous_context

        relationships = context.relationship_manifest()
        manifest["project_extensions"] = {
            "schema": "WBP-V3-EXTENDS-EXTERNAL_INTERIOR",
            "relationships": relationships,
            "relationship_count": len(relationships),
            "contribution_count": sum(len(rows) for rows in context.contributions.values()),
            "composition_order": "parent source ILF -> parent local INTERIOR order -> contributor publish_id -> contributor local_id",
            "runtime_ids_persisted_in_wbp": False,
        }
        validation = manifest.setdefault("validation", {})
        validation["project_extension_graph_valid"] = True
        validation["project_extension_targets_exist"] = True
        validation["project_extension_cycles_absent"] = True
        validation["external_interior_cells_rooms_validated"] = True
        validation["external_contributions_composed_into_parent_ilf"] = True

        # original_build_candidate already wrote the manifest. Rewrite only that
        # metadata file with the extension audit fields; generated TRE/Lua/OID
        # hashes and artifacts are unchanged by this final JSON annotation.
        candidate_dir = batch._config_required_path(config, config_path, "candidate_dir")
        batch._atomic_write_json(candidate_dir / batch.CANDIDATE_MANIFEST_NAME, manifest)
        return manifest

    def deploy_candidate(config_path: Path, manifest_path: Optional[Path], confirm_refreshed: bool) -> dict:
        config_path = Path(config_path).resolve()
        config = wb.load_config(config_path)
        candidate_dir = batch._config_required_path(config, config_path, "candidate_dir")
        resolved_manifest = (
            candidate_dir / batch.CANDIDATE_MANIFEST_NAME
            if manifest_path is None
            else Path(manifest_path).resolve()
        )
        manifest = batch._load_json(resolved_manifest, "candidate publish manifest")
        _manifest_publish_set_fresh(batch, config_path, manifest)
        return original_deploy_candidate(config_path, manifest_path, confirm_refreshed)

    wb.bake_snapshot_v2 = bake_snapshot_v2
    batch._project_fingerprint = project_fingerprint
    batch._project_manifest_entry = project_manifest_entry
    batch.validate_project_assets = validate_project_assets
    batch.build_candidate = build_candidate
    batch.deploy_candidate = deploy_candidate
    batch.build_extension_context = lambda approved: build_extension_context(wb, approved)
    batch.extension_dependents_for = dependents_for
    batch._bellum_batch_extensions_v3_installed = True


def activation_block() -> str:
    return '''\n# Bellum Gero World Builder V1.9.8 - desired-state WBP V3 extension composer.\n# Install after the proven batch implementation is defined so wrappers preserve V1/V2 behavior.\nimport worldbuilder_batch_extensions as _wb_batch_extensions\n_wb_batch_extensions.install(sys.modules[__name__])\n\n'''
