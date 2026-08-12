#!/usr/bin/env python3
"""Bellum Gero World Builder WBP V3 project-extension support.

This module is intentionally layered on top of the proven V1/V2 companion tool.
It leaves the existing V1/V2 parser/baker paths unchanged and adds only the
cross-project records needed for extension projects:

    EXTENDS <parent_publish_id> <parent_structure_local_id>
    EXTERNAL_INTERIOR <local_id> <server_template> <shared_template>
        <x> <z> <y> <qw> <qx> <qy> <qz> <snapshot_type>
        <parent_publish_id> <parent_structure_local_id> <cell_number> <room_name>

The batch extension module composes EXTERNAL_INTERIOR records into the parent
structure's one final project-specific ILF. This module only owns WBP parsing,
validation, and safety wrappers for the legacy standalone commands.
"""

from __future__ import annotations

import argparse
import dataclasses
import sys
from pathlib import Path
from typing import Optional

WBP_EXTENSION_VERSION = 3


@dataclasses.dataclass(frozen=True)
class ProjectExtension:
    parent_publish_id: str
    parent_structure_local_id: int


@dataclasses.dataclass
class ProjectExternalInterior:
    local_id: int
    object_template: str
    snapshot_template: str
    x: float
    z: float
    y: float
    qw: float
    qx: float
    qy: float
    qz: float
    snapshot_game_object_type: float
    parent_publish_id: str
    parent_structure_local_id: int
    cell_number: int
    room_name: str


def _ensure_extension_fields(project) -> None:
    if not hasattr(project, "extensions"):
        project.extensions = []
    if not hasattr(project, "external_interiors"):
        project.external_interiors = []


def _header_version(path: Path, magic: str) -> int:
    if not path.exists():
        raise FileNotFoundError(path)
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if parts[0] != magic or len(parts) != 2:
            return 0
        try:
            return int(parts[1])
        except ValueError:
            return 0
    return 0


def _validate_transform(wb, record, where: str, label: str) -> None:
    if record.local_id <= 0:
        raise wb.WorldBuilderError(where + f"{label} local ID must be > 0: {record.local_id}")
    if not record.object_template.endswith(".iff"):
        raise wb.WorldBuilderError(where + f"{label} #{record.local_id}: object template is not .iff")
    if not record.snapshot_template.endswith(".iff"):
        raise wb.WorldBuilderError(where + f"{label} #{record.local_id}: snapshot template is not .iff")
    qnorm = (record.qw**2 + record.qx**2 + record.qy**2 + record.qz**2) ** 0.5
    if not (0.5 <= qnorm <= 1.5):
        raise wb.WorldBuilderError(
            where + f"{label} #{record.local_id}: quaternion norm {qnorm:.4f} looks invalid"
        )


def _read_v3(wb, path: Path):
    if not path.exists():
        raise wb.WorldBuilderError(f"Project file not found: {path}")

    project = wb.Project()
    project.version = WBP_EXTENSION_VERSION
    _ensure_extension_fields(project)
    valid_header = False

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        key = parts[0]

        try:
            if key == wb.WBP_MAGIC:
                if len(parts) != 2 or int(parts[1]) != WBP_EXTENSION_VERSION:
                    raise wb.WorldBuilderError(f"{path}:{line_number}: malformed WBP V3 project header")
                valid_header = True
            elif key == "PROJECT":
                project.name = parts[1]
            elif key == "PLANET":
                project.planet = parts[1].lower()
            elif key == "MOVE_STEP":
                project.move_step = float(parts[1])
            elif key == "ROTATE_STEP":
                project.rotate_step = float(parts[1])
            elif key == "SELECTED":
                project.selected = int(parts[1])
            elif key == "NEXT_ID":
                project.next_id = int(parts[1])
            elif key == "LAST_TEMPLATE":
                project.last_template = "" if parts[1] == "-" else parts[1]
            elif key == "GROUP":
                project.group_ids = [int(value) for value in parts[1:]]
            elif key == "EXTENDS":
                if len(parts) != 3:
                    raise wb.WorldBuilderError(
                        f"{path}:{line_number}: EXTENDS requires parent publish ID + structure local ID"
                    )
                project.extensions.append(
                    ProjectExtension(
                        parent_publish_id=parts[1],
                        parent_structure_local_id=int(parts[2]),
                    )
                )
            elif key == "OBJECT":
                if len(parts) != 13:
                    raise wb.WorldBuilderError(
                        f"{path}:{line_number}: OBJECT requires 12 values after OBJECT; got {len(parts)-1}"
                    )
                project.objects.append(
                    wb.ProjectObject(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                        parent_id=int(parts[12]),
                    )
                )
            elif key == "STRUCTURE":
                if len(parts) != 12:
                    raise wb.WorldBuilderError(
                        f"{path}:{line_number}: STRUCTURE requires 11 values after STRUCTURE; got {len(parts)-1}"
                    )
                project.structures.append(
                    wb.ProjectStructure(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                    )
                )
            elif key == "INTERIOR":
                if len(parts) != 15:
                    raise wb.WorldBuilderError(
                        f"{path}:{line_number}: INTERIOR requires 14 values after INTERIOR; got {len(parts)-1}"
                    )
                project.interiors.append(
                    wb.ProjectInterior(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                        structure_local_id=int(parts[12]),
                        cell_number=int(parts[13]),
                        room_name="" if parts[14] == "-" else parts[14],
                    )
                )
            elif key == "EXTERNAL_INTERIOR":
                if len(parts) != 16:
                    raise wb.WorldBuilderError(
                        f"{path}:{line_number}: EXTERNAL_INTERIOR requires 15 values after the record name; got {len(parts)-1}"
                    )
                project.external_interiors.append(
                    ProjectExternalInterior(
                        local_id=int(parts[1]),
                        object_template=parts[2],
                        snapshot_template=parts[3],
                        x=float(parts[4]),
                        z=float(parts[5]),
                        y=float(parts[6]),
                        qw=float(parts[7]),
                        qx=float(parts[8]),
                        qy=float(parts[9]),
                        qz=float(parts[10]),
                        snapshot_game_object_type=float(parts[11]),
                        parent_publish_id=parts[12],
                        parent_structure_local_id=int(parts[13]),
                        cell_number=int(parts[14]),
                        room_name="" if parts[15] == "-" else parts[15],
                    )
                )
            else:
                raise wb.WorldBuilderError(f"{path}:{line_number}: unknown record {key!r}")
        except wb.WorldBuilderError:
            raise
        except (IndexError, ValueError) as exc:
            raise wb.WorldBuilderError(f"{path}:{line_number}: malformed {key} record") from exc

    if not valid_header:
        raise wb.WorldBuilderError(f"{path}: missing {wb.WBP_MAGIC} 3 header")
    validate_project_v3(wb, project, path, getattr(wb, "_wb_v1_9_8_original_validate_project", None))
    return project


def validate_project_v3(wb, project, source: Optional[Path] = None, base_validator=None) -> None:
    _ensure_extension_fields(project)
    where = f"{source}: " if source else ""

    if project.version != WBP_EXTENSION_VERSION:
        raise wb.WorldBuilderError(where + f"unsupported WBP V3 validation request for version {project.version}")
    if not project.name:
        raise wb.WorldBuilderError(where + "project name is empty")
    if not project.planet:
        raise wb.WorldBuilderError(where + "planet is empty")
    if not (0.01 <= project.move_step <= 25.0):
        raise wb.WorldBuilderError(where + f"move_step {project.move_step} outside 0.01..25")
    if not (0.1 <= project.rotate_step <= 90.0):
        raise wb.WorldBuilderError(where + f"rotate_step {project.rotate_step} outside 0.1..90")

    # Preserve the proven V2 validation rules verbatim for all legacy/local
    # records. Only the V3 extension records are validated below. External
    # local IDs are temporarily omitted from GROUP for this compatibility pass
    # because the V2 validator cannot know about EXTERNAL_INTERIOR yet.
    if base_validator is not None:
        local_ids = {int(value.local_id) for value in project.objects}
        local_ids.update(int(value.local_id) for value in project.structures)
        local_ids.update(int(value.local_id) for value in project.interiors)
        compatibility = wb.Project(
            version=wb.WBP_STRUCTURAL_VERSION,
            name=project.name,
            planet=project.planet,
            move_step=project.move_step,
            rotate_step=project.rotate_step,
            selected=project.selected,
            next_id=project.next_id,
            last_template=project.last_template,
            objects=list(project.objects),
            structures=list(project.structures),
            interiors=list(project.interiors),
            group_ids=[gid for gid in project.group_ids if int(gid) in local_ids],
        )
        base_validator(compatibility, source)

    extension_keys: set[tuple[str, int]] = set()
    for extension in project.extensions:
        parent = str(extension.parent_publish_id)
        if not parent or wb.project_slug(parent) != parent:
            raise wb.WorldBuilderError(
                where + f"EXTENDS parent publish ID {parent!r} is not canonical; expected {wb.project_slug(parent)!r}"
            )
        if extension.parent_structure_local_id <= 0:
            raise wb.WorldBuilderError(where + "EXTENDS structure local ID must be > 0")
        key = (parent, int(extension.parent_structure_local_id))
        if key in extension_keys:
            raise wb.WorldBuilderError(
                where + f"duplicate EXTENDS relationship: {parent} / Structure #{extension.parent_structure_local_id}"
            )
        extension_keys.add(key)

    seen: set[int] = set()
    for obj in project.objects:
        _validate_transform(wb, obj, where, "WB")
        if obj.local_id in seen:
            raise wb.WorldBuilderError(where + f"duplicate local ID {obj.local_id}")
        seen.add(obj.local_id)
        if obj.parent_id < 0:
            raise wb.WorldBuilderError(where + f"WB #{obj.local_id}: parent ID cannot be negative")

    for structure in project.structures:
        _validate_transform(wb, structure, where, "STRUCTURE")
        if structure.local_id in seen:
            raise wb.WorldBuilderError(where + f"duplicate local ID {structure.local_id}")
        seen.add(structure.local_id)

    structure_ids = {int(structure.local_id) for structure in project.structures}
    for interior in project.interiors:
        _validate_transform(wb, interior, where, "INTERIOR")
        if interior.local_id in seen:
            raise wb.WorldBuilderError(where + f"duplicate local ID {interior.local_id}")
        seen.add(interior.local_id)
        if interior.structure_local_id not in structure_ids:
            raise wb.WorldBuilderError(
                where + f"INTERIOR #{interior.local_id}: missing STRUCTURE #{interior.structure_local_id}"
            )
        if interior.cell_number <= 0:
            raise wb.WorldBuilderError(where + f"INTERIOR #{interior.local_id}: cell number must be > 0")

    for interior in project.external_interiors:
        _validate_transform(wb, interior, where, "EXTERNAL_INTERIOR")
        if interior.local_id in seen:
            raise wb.WorldBuilderError(where + f"duplicate local ID {interior.local_id}")
        seen.add(interior.local_id)
        parent = str(interior.parent_publish_id)
        if not parent or wb.project_slug(parent) != parent:
            raise wb.WorldBuilderError(
                where + f"EXTERNAL_INTERIOR #{interior.local_id}: parent publish ID {parent!r} is not canonical"
            )
        target = (parent, int(interior.parent_structure_local_id))
        if target not in extension_keys:
            raise wb.WorldBuilderError(
                where
                + f"EXTERNAL_INTERIOR #{interior.local_id}: target {parent} / Structure #{interior.parent_structure_local_id} "
                + "is not declared by an EXTENDS record"
            )
        if interior.parent_structure_local_id <= 0:
            raise wb.WorldBuilderError(
                where + f"EXTERNAL_INTERIOR #{interior.local_id}: parent structure local ID must be > 0"
            )
        if interior.cell_number <= 0:
            raise wb.WorldBuilderError(
                where + f"EXTERNAL_INTERIOR #{interior.local_id}: cell number must be > 0"
            )

    missing_group = [gid for gid in project.group_ids if gid not in seen]
    if missing_group:
        raise wb.WorldBuilderError(where + f"group references missing object IDs: {missing_group}")


def install(wb) -> None:
    """Install WBP V3 behavior into the existing bellum_worldbuilder module."""
    if getattr(wb, "_bellum_project_extensions_v3_installed", False):
        return

    original_read_project = wb.read_project
    original_validate_project = wb.validate_project
    original_generate_lua = wb.generate_lua
    original_bake_tre_v2 = wb.bake_tre_v2

    wb.WBP_EXTENSION_VERSION = WBP_EXTENSION_VERSION
    wb.ProjectExtension = ProjectExtension
    wb.ProjectExternalInterior = ProjectExternalInterior

    def read_project(path: Path):
        path = Path(path)
        try:
            version = _header_version(path, wb.WBP_MAGIC)
        except FileNotFoundError as exc:
            raise wb.WorldBuilderError(f"Project file not found: {path}") from exc
        if version == WBP_EXTENSION_VERSION:
            return _read_v3(wb, path)
        project = original_read_project(path)
        _ensure_extension_fields(project)
        return project

    def validate_project(project, source: Optional[Path] = None) -> None:
        _ensure_extension_fields(project)
        if project.version == WBP_EXTENSION_VERSION:
            return validate_project_v3(wb, project, source, original_validate_project)
        original_validate_project(project, source)
        if project.extensions or project.external_interiors:
            raise wb.WorldBuilderError("WBP V1/V2 cannot contain cross-project extension records")

    def generate_lua(project) -> str:
        _ensure_extension_fields(project)
        if project.extensions or project.external_interiors:
            raise wb.WorldBuilderError(
                "Cross-project WBP V3 extensions are structural desired-state content and cannot be exported as a Lua placement screenplay."
            )
        return original_generate_lua(project)

    def bake_tre_v2(project, *args, **kwargs):
        _ensure_extension_fields(project)
        if project.extensions or project.external_interiors:
            raise wb.WorldBuilderError(
                "WBP V3 cross-project extensions require the desired-state batch publisher. Use 'wb bake <project>' / 'wb bake', not standalone bake-tre."
            )
        return original_bake_tre_v2(project, *args, **kwargs)

    # Keep the original Project class intact (important for V1/V2), but make its
    # two convenience properties aware of dynamic V3 fields.
    wb.Project.is_structural = property(
        lambda self: self.version >= wb.WBP_STRUCTURAL_VERSION
        or bool(self.structures or self.interiors)
        or bool(getattr(self, "extensions", []))
        or bool(getattr(self, "external_interiors", []))
    )
    wb.Project.total_records = property(
        lambda self: len(self.objects)
        + len(self.structures)
        + len(self.interiors)
        + len(getattr(self, "external_interiors", []))
    )

    wb.read_project = read_project
    wb.validate_project = validate_project
    wb.generate_lua = generate_lua
    wb.bake_tre_v2 = bake_tre_v2
    wb._bellum_project_extensions_v3_installed = True

    # Preserve a few originals for regression/debugging without altering normal callers.
    wb._wb_v1_9_8_original_read_project = original_read_project
    wb._wb_v1_9_8_original_validate_project = original_validate_project


def activation_block() -> str:
    """Text inserted near the end of bellum_worldbuilder.py by the installer."""
    return '''\n# Bellum Gero World Builder V1.9.8 - WBP V3 project-extension layer.\n# Imported late so the proven V1/V2 implementation is defined first, then extended.\nimport worldbuilder_project_extensions as _wb_project_extensions\n_wb_project_extensions.install(sys.modules[__name__])\n\n'''
