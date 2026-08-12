#!/usr/bin/env python3
"""Operator-friendly Bellum Gero World Builder publishing commands."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[2]
DEFAULT_CONFIG = HERE / "worldbuilder_config.json"

sys.path.insert(0, str(HERE))

import bellum_worldbuilder as wb
import worldbuilder_batch as batch


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def _config_path(value: str | None) -> Path:
    if value:
        return Path(value).expanduser().resolve()
    env = os.environ.get("BELLUM_WB_CONFIG")
    if env:
        return Path(env).expanduser().resolve()
    return DEFAULT_CONFIG.resolve()


def _load_config(path: Path) -> dict:
    if not path.is_file():
        raise wb.WorldBuilderError(
            f"World Builder config not found: {path}\n"
            "Install/create MMOCoreORB/tools/worldbuilder/worldbuilder_config.json first."
        )
    return wb.load_config(path)


def _resolve(path: Path, value: str) -> Path:
    p = Path(value).expanduser()
    if not p.is_absolute():
        p = path.parent / p
    return p.resolve()


def _publish_set_path(config: dict, config_path: Path) -> Path:
    value = config.get("publish_set")
    if not value:
        raise wb.WorldBuilderError("Config is missing publish_set")
    return _resolve(config_path, str(value))


def _candidate_manifest_path(config: dict, config_path: Path) -> Path:
    value = config.get("candidate_dir")
    if not value:
        raise wb.WorldBuilderError("Config is missing candidate_dir")
    return _resolve(config_path, str(value)) / batch.CANDIDATE_MANIFEST_NAME


def _project_dir() -> Path:
    return REPO_ROOT / "MMOCoreORB/bin/worldbuilder/projects"


def _load_publish_payload(path: Path) -> dict:
    if not path.exists():
        return {"version": 1, "projects": []}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise wb.WorldBuilderError(f"Invalid publish set JSON: {path}: {exc}") from exc
    if not isinstance(payload, dict) or payload.get("version") != 1:
        raise wb.WorldBuilderError(f"Unsupported publish set: {path}")
    rows = payload.get("projects", [])
    if not isinstance(rows, list):
        raise wb.WorldBuilderError("publish_set projects must be an array")
    return payload


def _write_publish_payload(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    os.replace(temp, path)


def _find_project(token: str, publish_payload: dict) -> tuple[Path, wb.Project, str]:
    projects_dir = _project_dir()
    if not projects_dir.is_dir():
        raise wb.WorldBuilderError(f"World Builder projects directory not found: {projects_dir}")

    token_slug = wb.project_slug(token)
    matches: list[tuple[Path, wb.Project]] = []

    direct = projects_dir / token
    if direct.suffix.lower() != ".wbp":
        direct = projects_dir / f"{token}.wbp"
    if direct.is_file():
        project = wb.read_project(direct)
        matches.append((direct.resolve(), project))

    for path in sorted(projects_dir.glob("*.wbp")):
        resolved = path.resolve()
        if any(existing == resolved for existing, _ in matches):
            continue
        try:
            project = wb.read_project(path)
        except Exception:
            continue
        candidates = {
            wb.project_slug(path.stem),
            wb.project_slug(project.name or path.stem),
        }
        if token_slug in candidates:
            matches.append((resolved, project))

    if not matches:
        raise wb.WorldBuilderError(
            f"No WBP project matched {token!r} under {projects_dir}"
        )
    if len(matches) > 1:
        listing = "\n".join(f"  {path}" for path, _ in matches)
        raise wb.WorldBuilderError(
            f"Project name {token!r} is ambiguous:\n{listing}"
        )

    source, project = matches[0]

    existing_id = None
    for row in publish_payload.get("projects", []):
        if not isinstance(row, dict):
            continue
        raw_file = row.get("file")
        if not isinstance(raw_file, str):
            continue
        if Path(raw_file).name == source.name:
            existing_id = str(row.get("id") or "")
            if existing_id:
                break

    publish_id = existing_id or wb.project_slug(project.name or source.stem)
    return source, project, publish_id


def _print_candidate(manifest: dict) -> None:
    changes = manifest["changes_from_last_deploy"]
    candidate = Path(manifest["candidate_dir"]) / manifest["artifacts"]["tre"]
    print("World Builder overlay candidate validated.")
    print(f"Source TRE:    {manifest['base_tre']}")
    print(f"Candidate TRE: {candidate}")
    print(f"Projects:      {len(manifest['projects'])}")
    print(
        "Changes:       "
        f"added={len(changes['added'])}, "
        f"updated={len(changes['updated'])}, "
        f"removed={len(changes['removed'])}, "
        f"unchanged={len(changes['unchanged'])}"
    )
    print(
        "OID registry:  "
        f"active={manifest['registry_counts']['active']}, "
        f"retired={manifest['registry_counts']['retired']}, "
        f"historical={manifest['registry_counts']['historical_total']}"
    )
    print(f"Overlay files: {len(manifest.get('overlay_archive_paths', []))}")
    print(f"TRE SHA256:    {manifest['hashes']['tre_sha256']}")
    if changes["refresh_required"]:
        print("\nRefresh required before deployment:")
        for item in changes["refresh_required"]:
            print(f"  {item['id']} [{item['reason']}] on {item['planet']}")
            print(f"    {item['dry_run_command']}")
            print(f"    {item['confirm_command']}")
        print("\nAfter the refresh confirms pass, shut Core3 down and run:")
        print("  wb deploy refreshed")
    else:
        print("\nRefresh required before deployment: none")
        print("Next:")
        print("  wb deploy")


def cmd_bake(args: argparse.Namespace) -> int:
    config_path = _config_path(args.config)
    config = _load_config(config_path)
    publish_path = _publish_set_path(config, config_path)

    if args.project is None:
        manifest = batch.build_candidate(config_path)
        _print_candidate(manifest)
        return 0

    payload = _load_publish_payload(publish_path)
    original_bytes = publish_path.read_bytes() if publish_path.exists() else None

    source, project, publish_id = _find_project(args.project, payload)
    rows = payload.setdefault("projects", [])
    rel = os.path.relpath(source, publish_path.parent).replace(os.sep, "/")

    by_id = {
        str(row.get("id")): row
        for row in rows
        if isinstance(row, dict) and row.get("id")
    }

    existing = by_id.get(publish_id)
    if existing is not None:
        old_file = existing.get("file")
        if old_file and Path(str(old_file)).name != source.name:
            raise wb.WorldBuilderError(
                f"Publish ID {publish_id!r} already belongs to {old_file}; "
                "publish IDs are permanent and cannot be reassigned."
            )
        existing["file"] = rel
        existing["enabled"] = True
    else:
        rows.append(
            {
                "id": publish_id,
                "file": rel,
                "enabled": True,
            }
        )

    rows.sort(key=lambda row: str(row.get("id", "")))
    _write_publish_payload(publish_path, payload)

    try:
        manifest = batch.build_candidate(config_path)
    except Exception:
        if original_bytes is None:
            publish_path.unlink(missing_ok=True)
        else:
            publish_path.write_bytes(original_bytes)
        raise

    print(f"Approved project: {publish_id} ({source.name})")
    _print_candidate(manifest)
    return 0


def cmd_remove(args: argparse.Namespace) -> int:
    config_path = _config_path(args.config)
    config = _load_config(config_path)
    publish_path = _publish_set_path(config, config_path)
    payload = _load_publish_payload(publish_path)
    original_bytes = publish_path.read_bytes() if publish_path.exists() else None

    token = wb.project_slug(args.project)
    rows = payload.get("projects", [])
    kept = []
    removed = []

    for row in rows:
        if not isinstance(row, dict):
            kept.append(row)
            continue
        row_id = wb.project_slug(str(row.get("id", "")))
        file_slug = wb.project_slug(Path(str(row.get("file", ""))).stem)
        if token in {row_id, file_slug}:
            removed.append(row)
        else:
            kept.append(row)

    if not removed:
        raise wb.WorldBuilderError(f"Project {args.project!r} is not in the approved publish set")

    if len(removed) > 1:
        raise wb.WorldBuilderError(f"Project token {args.project!r} matched more than one approved entry")

    payload["projects"] = kept
    _write_publish_payload(publish_path, payload)

    try:
        manifest = batch.build_candidate(config_path)
    except Exception:
        if original_bytes is None:
            publish_path.unlink(missing_ok=True)
        else:
            publish_path.write_bytes(original_bytes)
        raise

    print(f"Unpublished project: {removed[0].get('id')}")
    print("The .wbp file was not deleted.")
    _print_candidate(manifest)
    return 0


def cmd_deploy(args: argparse.Namespace) -> int:
    config_path = _config_path(args.config)
    confirm = args.mode == "refreshed"
    result = batch.deploy_candidate(config_path, None, confirm)
    print("World Builder overlay deployment complete.")
    print(f"Client TRE: {result['client_tre']}")
    print(f"Server TRE: {result['server_tre']}")
    print(f"Server Lua: {result['server_template_lua']}")
    print(f"TRE SHA256: {result['tre_sha256']}")
    print("Client and server received byte-identical bg_worldbuilder.tre files.")
    return 0


def cmd_projects(args: argparse.Namespace) -> int:
    config_path = _config_path(args.config)
    config = _load_config(config_path)
    publish_path = _publish_set_path(config, config_path)
    payload = _load_publish_payload(publish_path)
    approved = {
        str(row.get("id")): Path(str(row.get("file", ""))).name
        for row in payload.get("projects", [])
        if isinstance(row, dict) and row.get("enabled", True) is not False
    }

    state_path = batch._config_required_path(config, config_path, "deployed_state")
    state = batch.load_deployed_state(state_path)
    deployed = {str(row.get("id")) for row in state.get("projects", []) if isinstance(row, dict)}

    rows = []
    for path in sorted(_project_dir().glob("*.wbp")):
        try:
            project = wb.read_project(path)
            version = f"V{project.version}"
            identity = None
            for publish_id, file_name in approved.items():
                if file_name == path.name:
                    identity = publish_id
                    break
            if identity and identity in deployed:
                status = "Published"
            elif identity:
                status = "Approved / not deployed"
            else:
                status = "Not published"
            rows.append((path.stem, version, project.planet, status, identity or "-"))
        except Exception as exc:
            rows.append((path.stem, "?", "?", f"INVALID: {exc}", "-"))

    if not rows:
        print("No .wbp projects found.")
        return 0

    print(f"{'PROJECT':30} {'WBP':4} {'PLANET':12} {'STATUS':24} PUBLISH ID")
    print("-" * 100)
    for row in rows:
        print(f"{row[0]:30} {row[1]:4} {row[2]:12} {row[3]:24} {row[4]}")
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    config_path = _config_path(args.config)
    config = _load_config(config_path)

    source_tre = batch._config_required_path(config, config_path, "base_tre")
    output_name = str(config.get("output_tre_name") or batch.CANDIDATE_TRE_NAME_FALLBACK)
    client_dir = batch._config_required_path(config, config_path, "client_tre_dir")
    server_dir = batch._config_required_path(config, config_path, "server_tre_dir")
    state_path = batch._config_required_path(config, config_path, "deployed_state")
    publish_path = _publish_set_path(config, config_path)

    client_overlay = client_dir / output_name
    server_overlay = server_dir / output_name
    client_source = client_dir / source_tre.name

    state = batch.load_deployed_state(state_path)
    publish = _load_publish_payload(publish_path)
    approved = [
        row for row in publish.get("projects", [])
        if isinstance(row, dict) and row.get("enabled", True) is not False
    ]

    print("Bellum Gero World Builder")
    print()
    print("NORMAL CUSTOM TRE")
    if source_tre.exists():
        source_sha = _sha256(source_tre)
        print(f"  Server source: {source_tre}")
        print(f"  SHA256:        {source_sha}")
    else:
        source_sha = None
        print(f"  Server source: MISSING - {source_tre}")

    if client_source.exists() and source_sha:
        client_sha = _sha256(client_source)
        match = client_sha == source_sha
        print(f"  Client source: {client_source}")
        print(f"  Client/server bg_custom1 match: {'YES' if match else 'NO'}")
    else:
        print(f"  Client source: {'MISSING' if not client_source.exists() else client_source}")

    print()
    print("CANONICAL SOURCE STACK")
    try:
        stack = batch._effective_tre_stack(config, config_path, source_tre, output_name)
        print(f"  Config:     {stack.config_lua}")
        print(f"  Lower TREs: {len(stack.tre_names)}")
        if stack.tre_names:
            preview = " -> ".join(stack.tre_names[:3])
            if len(stack.tre_names) > 3:
                preview += " -> ... -> " + stack.tre_names[-1]
            print(f"  Priority:   {preview}")
        print("  Status:     READY")
    except Exception as exc:
        print(f"  Status:     ERROR - {exc}")

    print()
    print("WORLD BUILDER OVERLAY")
    expected = state.get("tre_sha256")
    for label, path in (("Server", server_overlay), ("Client", client_overlay)):
        if not path.exists():
            print(f"  {label}: not deployed")
        else:
            actual = _sha256(path)
            if expected:
                status = "OK" if actual == expected else "DRIFTED"
                print(f"  {label}: {status} - {path}")
            else:
                print(f"  {label}: present but not recorded as deployed - {path}")

    if client_overlay.exists() and server_overlay.exists():
        print(
            "  Client/server overlay match: "
            + ("YES" if _sha256(client_overlay) == _sha256(server_overlay) else "NO")
        )

    dependency = batch.dependency_status(config_path)
    print()
    print("DEPENDENCIES")
    if not state.get("projects"):
        print("  No deployed World Builder projects.")
    elif dependency["stale"]:
        print("  STALE - a source record used by bg_worldbuilder.tre changed.")
        for item in dependency["changed"]:
            print(f"    {item['path']}: {item['reason']}")
        print("  Run: wb bake")
    else:
        print(f"  CURRENT - {dependency['checked']} tracked source record(s) unchanged.")

    print()
    print("PROJECTS")
    print(f"  Approved: {len(approved)}")
    print(f"  Deployed: {len(state.get('projects', []))}")

    candidate_path = _candidate_manifest_path(config, config_path)
    print()
    print("CANDIDATE")
    if not candidate_path.exists():
        print("  None")
    else:
        try:
            manifest = json.loads(candidate_path.read_text(encoding="utf-8"))
            changes = manifest.get("changes_from_last_deploy", {})
            print(f"  {candidate_path}")
            print(
                "  Changes: "
                f"added={len(changes.get('added', []))}, "
                f"updated={len(changes.get('updated', []))}, "
                f"removed={len(changes.get('removed', []))}, "
                f"unchanged={len(changes.get('unchanged', []))}"
            )
        except Exception:
            print(f"  Invalid candidate manifest: {candidate_path}")
    return 0


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="wb",
        description="Bellum Gero World Builder production publishing commands",
        epilog="""Common workflow:
  wb status
  wb bake <project>
  wb deploy

For an update/removal that prints refreshpublished commands:
  run the printed /wb commands while the old TRE is active
  shut Core3 down
  wb deploy refreshed
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--config",
        help="World Builder config override (default: MMOCoreORB/tools/worldbuilder/worldbuilder_config.json)",
    )

    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("status", help="show TRE, project, candidate, and dependency status")
    p.set_defaults(func=cmd_status)

    p = sub.add_parser("projects", help="list saved WBP projects and publish status")
    p.set_defaults(func=cmd_projects)

    p = sub.add_parser("bake", help="build the complete bg_worldbuilder.tre candidate")
    p.add_argument(
        "project",
        nargs="?",
        help="optional project to approve/add/update before rebuilding the complete overlay",
    )
    p.set_defaults(func=cmd_bake)

    p = sub.add_parser("remove", help="unpublish a project and rebuild the complete overlay")
    p.add_argument("project")
    p.set_defaults(func=cmd_remove)

    p = sub.add_parser("deploy", help="deploy the validated bg_worldbuilder.tre candidate")
    p.add_argument(
        "mode",
        nargs="?",
        choices=["refreshed"],
        help="use 'refreshed' only after completing required /wb refreshpublished commands",
    )
    p.set_defaults(func=cmd_deploy)

    return parser


def main(argv=None) -> int:
    parser = make_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except wb.WorldBuilderError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("Cancelled.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
