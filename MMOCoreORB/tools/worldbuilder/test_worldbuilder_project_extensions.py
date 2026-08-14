#!/usr/bin/env python3
"""Regression checks for Bellum Gero World Builder V1.9.8 project extensions.

These tests intentionally avoid TRE/IFF assets. They exercise the compatibility
surface that can be validated from project manifests alone: V1/V2 parsing,
V3 records, dependency graph safety, and deterministic contribution ordering.
"""

from __future__ import annotations

import tempfile
import unittest
import struct
import re
from pathlib import Path

import bellum_worldbuilder as wb
import worldbuilder_batch as batch
import worldbuilder_batch_extensions as batch_ext
from types import SimpleNamespace


def write_project(root: Path, name: str, text: str) -> Path:
    path = root / name
    path.write_text(text.strip() + "\n", encoding="utf-8")
    return path


def structure(local_id: int = 1):
    return wb.ProjectStructure(
        local_id=local_id,
        object_template="object/building/test/cave.iff",
        snapshot_template="object/building/test/shared_cave.iff",
        x=0.0,
        z=0.0,
        y=0.0,
        qw=1.0,
        qx=0.0,
        qy=0.0,
        qz=0.0,
        snapshot_game_object_type=512.0,
    )


def approved(publish_id: str, project, root: Path):
    path = root / f"{publish_id}.wbp"
    path.write_text(f"# synthetic test source for {publish_id}\n", encoding="utf-8")
    return batch.ApprovedProject(
        publish_id=publish_id,
        source_path=path,
        project=project,
        wbp_sha256=(publish_id * 8)[:64],
    )


def make_parent(name: str = "parent", planet: str = "lok"):
    return wb.Project(
        version=wb.WBP_STRUCTURAL_VERSION,
        name=name,
        planet=planet,
        structures=[structure(1)],
    )


def make_child(name: str, parent_id: str = "parent", planet: str = "lok", local_id: int = 1):
    project = wb.Project(
        version=wb.WBP_EXTENSION_VERSION,
        name=name,
        planet=planet,
    )
    project.extensions = [wb.ProjectExtension(parent_id, 1)]
    project.external_interiors = [
        wb.ProjectExternalInterior(
            local_id=local_id,
            object_template="object/static/test/decor.iff",
            snapshot_template="object/static/test/shared_decor.iff",
            x=float(local_id),
            z=0.0,
            y=0.0,
            qw=1.0,
            qx=0.0,
            qy=0.0,
            qz=0.0,
            snapshot_game_object_type=-1.0,
            parent_publish_id=parent_id,
            parent_structure_local_id=1,
            cell_number=2,
            room_name="r2",
        )
    ]
    return project


def iff_chunk(tag: bytes, payload: bytes) -> bytes:
    return tag + struct.pack(">I", len(payload)) + payload


def static_ship_reference() -> bytes:
    derv = iff_chunk(b"DERV", b"object/static/base/shared_static_base.iff\0")
    # Real SWG STAT IFFs place the next chunk immediately after an odd payload.
    odd = iff_chunk(b"XXXX", b"oddField\0\x01abcdefghij\0")  # exactly 21 bytes
    appearance = iff_chunk(b"XXXX", b"appearanceFilename\0\x01appearance/tie_fighter.apt\0")
    version = iff_chunk(b"FORM", b"0007" + odd + appearance)
    shot = iff_chunk(b"FORM", b"SHOT" + version)
    return iff_chunk(b"FORM", b"STAT" + derv + shot)


def object_template_crc_table(paths) -> bytes:
    values = sorted(paths)
    count = len(values)
    body = b"".join((
        iff_chunk(b"DATA", struct.pack("<I", count)),
        iff_chunk(b"CRCT", b"\0" * (count * 4)),
        iff_chunk(b"STRT", b"\0" * (count * 4)),
        iff_chunk(b"STNG", b"".join(path.encode("utf-8") + b"\0" for path in values)),
    ))
    return iff_chunk(b"FORM", b"CSTB" + iff_chunk(b"FORM", b"0000" + body))


def validate_iff_chunk_sizes(raw: bytes, start: int = 0, limit: int | None = None) -> int:
    limit = len(raw) if limit is None else limit
    size = struct.unpack_from(">I", raw, start + 4)[0]
    data_start = start + 8
    data_end = data_start + size
    end = data_end
    if raw[start:start + 4] == b"FORM":
        cursor = data_start + 4
        while cursor < data_end:
            cursor = validate_iff_chunk_sizes(raw, cursor, data_end)
        if cursor != data_end:
            raise AssertionError("FORM children do not fill declared size")
    if end > limit:
        raise AssertionError("chunk exceeds parent")
    return end


class ProjectParsingTests(unittest.TestCase):
    def test_v1_parser_unchanged(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = write_project(
                root,
                "v1.wbp",
                """
                BELLUM_GERO_WORLD_BUILDER 1
                PROJECT v1
                PLANET lok
                MOVE_STEP 0.1
                ROTATE_STEP 5
                SELECTED 1
                NEXT_ID 2
                LAST_TEMPLATE -
                OBJECT 1 object/static/test/decor.iff object/static/test/shared_decor.iff 1 2 3 1 0 0 0 -1 0
                """,
            )
            project = wb.read_project(path)
            self.assertEqual(project.version, 1)
            self.assertEqual(len(project.objects), 1)
            self.assertEqual(project.extensions, [])
            self.assertEqual(project.external_interiors, [])

    def test_v2_parser_unchanged(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = write_project(
                root,
                "v2.wbp",
                """
                BELLUM_GERO_WORLD_BUILDER 2
                PROJECT v2
                PLANET lok
                MOVE_STEP 0.1
                ROTATE_STEP 5
                SELECTED 2
                NEXT_ID 3
                LAST_TEMPLATE -
                STRUCTURE 1 object/building/test/cave.iff object/building/test/shared_cave.iff 0 0 0 1 0 0 0 512
                INTERIOR 2 object/static/test/decor.iff object/static/test/shared_decor.iff 1 2 3 1 0 0 0 -1 1 2 r2
                """,
            )
            project = wb.read_project(path)
            self.assertEqual(project.version, 2)
            self.assertEqual(len(project.structures), 1)
            self.assertEqual(len(project.interiors), 1)
            self.assertEqual(project.extensions, [])
            self.assertEqual(project.external_interiors, [])

    def test_v3_extends_and_external_interior_parse(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = write_project(
                root,
                "v3.wbp",
                """
                BELLUM_GERO_WORLD_BUILDER 3
                PROJECT phase2
                PLANET lok
                MOVE_STEP 0.1
                ROTATE_STEP 5
                SELECTED 1
                NEXT_ID 2
                LAST_TEMPLATE object/static/test/decor.iff
                EXTENDS droid_cave 1
                EXTERNAL_INTERIOR 1 object/static/test/decor.iff object/static/test/shared_decor.iff 1 2 3 1 0 0 0 -1 droid_cave 1 2 r2
                GROUP 1
                """,
            )
            project = wb.read_project(path)
            self.assertEqual(project.version, 3)
            self.assertEqual(len(project.extensions), 1)
            self.assertEqual(len(project.external_interiors), 1)
            interior = project.external_interiors[0]
            self.assertEqual(interior.parent_publish_id, "droid_cave")
            self.assertEqual(interior.parent_structure_local_id, 1)
            self.assertEqual(interior.cell_number, 2)
            self.assertEqual(interior.room_name, "r2")

    def test_v3_external_interior_requires_declared_extends(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = write_project(
                root,
                "bad_v3.wbp",
                """
                BELLUM_GERO_WORLD_BUILDER 3
                PROJECT bad
                PLANET lok
                MOVE_STEP 0.1
                ROTATE_STEP 5
                SELECTED 1
                NEXT_ID 2
                LAST_TEMPLATE -
                EXTERNAL_INTERIOR 1 object/static/test/decor.iff object/static/test/shared_decor.iff 1 2 3 1 0 0 0 -1 droid_cave 1 2 r2
                """,
            )
            with self.assertRaisesRegex(wb.WorldBuilderError, "not declared by an EXTENDS"):
                wb.read_project(path)


    def test_v3_travel_point_name_round_trips_utf8_hex(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = write_project(Path(tmp), "travel.wbp", """
                BELLUM_GERO_WORLD_BUILDER 3
                PROJECT travel
                PLANET corellia
                MOVE_STEP 0.1
                ROTATE_STEP 5
                SELECTED 1
                NEXT_ID 2
                LAST_TEMPLATE -
                STRUCTURE 1 object/building/corellia/shuttleport_corellia.iff object/building/corellia/shared_shuttleport_corellia.iff 0 0 0 1 0 0 0 512
                TRAVEL_POINT 1 10 0 10 1 1 3 4576656e74204f7574706f7374
            """)
            project = wb.read_project(path)
            self.assertEqual(project.travel_points[0].point_name, "Event Outpost")
            self.assertTrue(project.is_structural)

    def test_v3_travel_point_rejects_out_of_range(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = write_project(Path(tmp), "far.wbp", """
                BELLUM_GERO_WORLD_BUILDER 3
                PROJECT travel
                PLANET corellia
                MOVE_STEP 0.1
                ROTATE_STEP 5
                SELECTED 1
                NEXT_ID 2
                LAST_TEMPLATE -
                STRUCTURE 1 object/building/corellia/shuttleport_corellia.iff object/building/corellia/shared_shuttleport_corellia.iff 0 0 0 1 0 0 0 512
                TRAVEL_POINT 1 121 0 0 1 1 3 466172
            """)
            with self.assertRaises(wb.WorldBuilderError):
                wb.read_project(path)


class CompositionTests(unittest.TestCase):
    def test_ship_scenery_crc_validation_uses_canonical_shared_paths(self):
        required = {path for _ship, path, _appearance in batch.SHIP_SCENERY_CATALOG}
        raw = object_template_crc_table(required)
        resolver = SimpleNamespace(read=lambda path: raw)

        self.assertEqual(batch.validate_ship_scenery_crc_requirements(resolver), raw)
        self.assertEqual(batch.parse_object_template_crc_strings(raw), required)

    def test_ship_scenery_crc_validation_reports_original_five_vs_missing_eighteen(self):
        original_five = {
            "object/static/worldbuilder/ship/rebel/shared_awing.iff",
            "object/static/worldbuilder/ship/imperial/shared_tie_interceptor.iff",
            "object/static/worldbuilder/ship/rebel/shared_xwing.iff",
            "object/static/worldbuilder/ship/rebel/shared_ywing.iff",
            "object/static/worldbuilder/ship/rebel/shared_z95.iff",
        }
        raw = object_template_crc_table(original_five)

        with self.assertRaisesRegex(
            wb.WorldBuilderError,
            r"(?s)missing 18 Ship Scenery.*ARC-170: object/static/worldbuilder/ship/republic/shared_arc170\.iff \(CRC 0x6A758872\).*bg_custom1\.tre",
        ):
            batch.validate_ship_scenery_crc_requirements(SimpleNamespace(read=lambda path: raw))

    def test_static_ship_scenery_walks_consecutive_unpadded_odd_chunks(self):
        source = static_ship_reference()
        odd_start = source.index(b"XXXX" + struct.pack(">I", 21))
        next_start = odd_start + 8 + 21

        self.assertEqual(source[next_start:next_start + 4], b"XXXX")
        generated = batch.generate_static_ship_scenery_iff(source, "appearance/xwing_body.apt")
        self.assertEqual(generated[odd_start + 8:next_start], b"oddField\0\x01abcdefghij\0")
        self.assertEqual(generated[next_start:next_start + 4], b"XXXX")
        self.assertNotEqual(generated[next_start:next_start + 1], b"\0")
        self.assertEqual(validate_iff_chunk_sizes(generated), len(generated))

    def test_static_ship_scenery_iff_rewrites_appearance_and_preserves_structure(self):
        source = static_ship_reference()
        generated = batch.generate_static_ship_scenery_iff(source, "appearance/xwing_body.apt")

        self.assertEqual(generated[:12], b"FORM" + struct.pack(">I", len(generated) - 8) + b"STAT")
        self.assertEqual(validate_iff_chunk_sizes(generated), len(generated))
        self.assertEqual(generated.count(b"appearanceFilename\0"), 1)
        self.assertEqual(generated.count(b"appearance/xwing_body.apt\0"), 1)
        self.assertNotIn(b"appearance/tie_fighter.apt", generated)
        self.assertIn(b"object/static/base/shared_static_base.iff\0", generated)
        self.assertEqual(generated, batch.generate_static_ship_scenery_iff(source, "appearance/xwing_body.apt"))

    def test_static_ship_scenery_iff_recalculates_longer_and_shorter_forms(self):
        source = static_ship_reference()
        for appearance in ("appearance/a.apt", "appearance/a_much_longer_test_ship_body.apt"):
            generated = batch.generate_static_ship_scenery_iff(source, appearance)
            self.assertEqual(struct.unpack_from(">I", generated, 4)[0], len(generated) - 8)
            self.assertEqual(validate_iff_chunk_sizes(generated), len(generated))

    def test_builtin_ship_assets_exist_without_any_projects(self):
        source = static_ship_reference()
        resolved = []
        def read(path):
            resolved.append(path)
            return source if path == batch.SHIP_SCENERY_BASE_IFF else b"appearance-root"
        resolver = SimpleNamespace(read=read)
        assets = batch.generate_builtin_ship_scenery_assets(resolver)

        expected = {
            "ARC-170": ("object/static/worldbuilder/ship/republic/shared_arc170.iff", "appearance/arc170_model.apt"),
            "X-Wing": ("object/static/worldbuilder/ship/rebel/shared_xwing.iff", "appearance/xwing_model.apt"),
            "A-Wing": ("object/static/worldbuilder/ship/rebel/shared_awing.iff", "appearance/a_wing_model.apt"),
            "B-Wing": ("object/static/worldbuilder/ship/rebel/shared_bwing.iff", "appearance/bwing_model.apt"),
            "Droid Fighter": ("object/static/worldbuilder/ship/separatist/shared_droid_fighter.iff", "appearance/droid_fighter_model.apt"),
            "Grievous Starship": ("object/static/worldbuilder/ship/separatist/shared_grievous_starship.iff", "appearance/grievous_starship_model.apt"),
            "Jedi Fighter": ("object/static/worldbuilder/ship/republic/shared_jedifighter.iff", "appearance/jedifighter_model.apt"),
            "KSE Firespray": ("object/static/worldbuilder/ship/civilian/shared_kse_firespray.iff", "appearance/kse_firespray_model.apt"),
            "Lambda Shuttle": ("object/static/worldbuilder/ship/imperial/shared_lambda_shuttle.iff", "appearance/lambda_shuttle_model.apt"),
            "Naboo Starfighter": ("object/static/worldbuilder/ship/republic/shared_naboo_starfighter.iff", "appearance/naboo_starfighter_model.apt"),
            "SoroSuub Space Yacht": ("object/static/worldbuilder/ship/civilian/shared_soorosuub_space_yacht.iff", "appearance/soorosuub_space_yacht_model.apt"),
            "TIE Advanced": ("object/static/worldbuilder/ship/imperial/shared_tie_advanced.iff", "appearance/tie_advanced_model.apt"),
            "TIE Aggressor": ("object/static/worldbuilder/ship/imperial/shared_tie_aggressor.iff", "appearance/tie_aggressor_model.apt"),
            "TIE Bomber": ("object/static/worldbuilder/ship/imperial/shared_tie_bomber.iff", "appearance/tie_bomber_model.apt"),
            "TIE Fighter": ("object/static/worldbuilder/ship/imperial/shared_tie_fighter.iff", "appearance/tie_fighter_model.apt"),
            "TIE Oppressor": ("object/static/worldbuilder/ship/imperial/shared_tie_oppressor.iff", "appearance/tie_oppressor_model.apt"),
            "V-Wing": ("object/static/worldbuilder/ship/republic/shared_v_wing.iff", "appearance/v_wing_model.apt"),
            "Y-Wing": ("object/static/worldbuilder/ship/rebel/shared_ywing.iff", "appearance/ywing_model.apt"),
            "YKL-37R": ("object/static/worldbuilder/ship/civilian/shared_ykl37r.iff", "appearance/ykl37r_model.apt"),
            "YT-1300": ("object/static/worldbuilder/ship/civilian/shared_yt1300.iff", "appearance/yt1300_model.apt"),
            "YT-2400": ("object/static/worldbuilder/ship/civilian/shared_yt2400.iff", "appearance/yt2400_model.apt"),
            "Z-95": ("object/static/worldbuilder/ship/rebel/shared_z95.iff", "appearance/z95_model.apt"),
            "TIE Interceptor": ("object/static/worldbuilder/ship/imperial/shared_tie_interceptor.iff", "appearance/tie_interceptor_model.apt"),
        }
        self.assertEqual(
            {ship: (path, appearance) for ship, path, appearance in batch.SHIP_SCENERY_CATALOG},
            expected,
        )
        self.assertEqual(set(assets), {path for path, _ in expected.values()})
        self.assertEqual(len(assets), 23)
        self.assertTrue(all(path.startswith("object/static/worldbuilder/ship/") for path in assets))
        self.assertFalse(any(path.startswith("appearance/") for path in assets))
        self.assertEqual({ship for ship, _path, _appearance in batch.SHIP_SCENERY_CATALOG}, set(expected))
        self.assertEqual(len({path for _ship, path, _appearance in batch.SHIP_SCENERY_CATALOG}), 23)
        self.assertEqual(len({appearance for _ship, _path, appearance in batch.SHIP_SCENERY_CATALOG}), 23)
        for _ship, path, appearance in batch.SHIP_SCENERY_CATALOG:
            self.assertIn(appearance.encode("utf-8") + b"\0", assets[path])
            self.assertIn(appearance, resolved)

    def test_ship_scenery_ui_uses_terrain_placement_and_zero_default_offsets(self):
        mmocore = Path(__file__).resolve().parents[2]
        library = (mmocore / "src/server/zone/objects/creature/commands/WorldBuilderShipSceneryLibrary.h").read_text(encoding="utf-8")
        manager = (mmocore / "src/server/zone/managers/worldbuilder/WorldBuilderManager.cpp").read_text(encoding="utf-8")
        server_lua = (mmocore / "bin/scripts/object/static/worldbuilder/serverobjects.lua").read_text(encoding="utf-8")
        rows = re.findall(r'\{ "([^"]+)", "([^"]+)", "(object/static/worldbuilder/ship/[^"]+\.iff)", ([-0-9.]+)f \}', library)
        lua_rows = re.findall(r'\{ "object_static_worldbuilder_ship_([^"]+)", "([^"]+)" \}', server_lua)

        self.assertEqual(len(rows), 23)
        self.assertEqual(len({name for _category, name, _path, _offset in rows}), 23)
        self.assertEqual(len({path for _category, _name, path, _offset in rows}), 23)
        self.assertTrue(all(float(offset) == 0.0 for _category, _name, _path, offset in rows))
        self.assertEqual(len(lua_rows), 23)
        self.assertEqual(
            {f"object/static/worldbuilder/ship/{folder}/shared_{name}.iff" for folder, name in lua_rows},
            {path for _ship, path, _appearance in batch.SHIP_SCENERY_CATALOG},
        )
        self.assertIn('"TIE Interceptor", "object/static/worldbuilder/ship/imperial/tie_interceptor.iff", 0.f', library)
        self.assertIn("spawnShipScenery(player, action, 10.f", library)
        self.assertIn("player->getZone()->getHeight(state.x, state.y) + groundOffset", manager)

    def test_builtin_ship_assets_identify_missing_lower_stack_appearance(self):
        source = static_ship_reference()
        def read(path):
            if path == batch.SHIP_SCENERY_BASE_IFF:
                return source
            if path == "appearance/ywing_model.apt":
                raise wb.WorldBuilderError("not found in test stack")
            return b"appearance-root"

        with self.assertRaisesRegex(
            wb.WorldBuilderError,
            "Y-Wing requires 'appearance/ywing_model.apt'.*effective lower TRE stack",
        ):
            batch.generate_builtin_ship_scenery_assets(SimpleNamespace(read=read))

    def test_generated_server_template_materializes_source_fields_before_registration(self):
        project = make_parent("event_bunker", "corellia")
        published = wb.PublishedStructure(
            local_id=4,
            root_object_id=1004,
            cell_object_ids=[],
            game_object_type=512,
            source_server_template="object/building/corellia/shuttleport_corellia.iff",
            source_shared_template="object/building/corellia/shared_shuttleport_corellia.iff",
            source_portal_layout="",
            source_interior_layout="",
            custom_server_template="object/building/worldbuilder/event_bunker/structure_4.iff",
            custom_shared_template="object/building/worldbuilder/event_bunker/shared_structure_4.iff",
            custom_interior_layout="",
            portal_crc=0,
            cell_count=0,
            interior_local_ids=[],
        )

        lua = wb.generate_server_template_lua(project, [published])
        custom = "object_building_worldbuilder_event_bunker_structure_4"
        source = "object_building_corellia_shuttleport_corellia"
        copy_start = lua.index(f"for key, value in pairs({source}) do")
        registration = lua.index(f"ObjectTemplates:addTemplate({custom}")

        self.assertLess(copy_start, registration)
        self.assertIn(f'if key ~= "__index" and rawget({custom}, key) == nil then', lua)
        self.assertIn(f"rawset({custom}, key, value)", lua)
        self.assertIn('clientTemplateFileName = "object/building/worldbuilder/event_bunker/shared_structure_4.iff"', lua)
        self.assertIn("gameObjectType = 512", lua)
        self.assertIn("totalCellNumber = 0", lua)

    def test_travel_lua_is_deterministic_and_escaped(self):
        project = make_parent("travel", "corellia")
        project.version = wb.WBP_EXTENSION_VERSION
        project.travel_points = [wb.ProjectTravelPoint(1, 'Event "Outpost"', 10, 0, 10, True, True, 3)]
        result = SimpleNamespace(approved=SimpleNamespace(project=project, publish_id="travel"))
        lua, rows = batch._combined_travel_lua([result])
        self.assertIn('name = "Event \\"Outpost\\""', lua)
        self.assertEqual(rows[0]["structure_local_id"], 1)

    def test_travel_lua_preserves_wbp_x_z_y_fields(self):
        project = make_parent("coordinates", "corellia")
        project.version = wb.WBP_EXTENSION_VERSION
        project.travel_points = [wb.ProjectTravelPoint(1, "Corellian Outpost", -177.864, 28.0, -4891.75, True, True, 3)]
        result = SimpleNamespace(approved=SimpleNamespace(project=project, publish_id="coordinates"))
        lua, rows = batch._combined_travel_lua([result])
        self.assertIn("x = -177.864", lua)
        self.assertIn("z = 28", lua)
        self.assertIn("y = -4891.75", lua)
        self.assertEqual((rows[0]["x"], rows[0]["z"], rows[0]["y"]), (-177.864, 28.0, -4891.75))

    def test_travel_lua_rejects_unsafe_proximity(self):
        first = make_parent("one", "corellia"); first.version = wb.WBP_EXTENSION_VERSION
        second = make_parent("two", "corellia"); second.version = wb.WBP_EXTENSION_VERSION
        first.travel_points = [wb.ProjectTravelPoint(1, "One", 0, 0, 0, True, True, 3)]
        second.travel_points = [wb.ProjectTravelPoint(1, "Two", 100, 0, 0, True, True, 3)]
        results = [SimpleNamespace(approved=SimpleNamespace(project=first, publish_id="one")), SimpleNamespace(approved=SimpleNamespace(project=second, publish_id="two"))]
        with self.assertRaises(wb.WorldBuilderError):
            batch._combined_travel_lua(results)

    def _with_fake_ilf_api(self, callback):
        names = [
            "read_string_param",
            "parse_portal_layout",
            "build_ilf_node",
            "append_ilf_nodes",
            "normalize_archive_path",
        ]
        had = {name: hasattr(wb, name) for name in names}
        originals = {name: getattr(wb, name, None) for name in names}
        old_context = batch_ext._ACTIVE_CONTEXT
        try:
            wb.read_string_param = lambda _raw, _field: "appearance/test_portal.prt"
            wb.parse_portal_layout = lambda _raw, _path: SimpleNamespace(
                cell_count=2, rooms=["outside", "r1", "r2"]
            )
            wb.build_ilf_node = lambda interior, room: f"{interior.local_id}:{room}|".encode()
            wb.append_ilf_nodes = lambda source, nodes, _name: source + b"".join(nodes)
            wb.normalize_archive_path = lambda value: str(value).lower()
            return callback()
        finally:
            batch_ext._ACTIVE_CONTEXT = old_context
            for name, value in originals.items():
                if had[name]:
                    setattr(wb, name, value)
                elif hasattr(wb, name):
                    delattr(wb, name)

    def test_external_nodes_append_in_contributor_then_local_id_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            parent = approved("parent", make_parent(), root)
            z_child = approved("z_child", make_child("z_child", local_id=7), root)
            a_child = approved("a_child", make_child("a_child", local_id=9), root)
            context = batch.build_extension_context([z_child, parent, a_child])

            def run():
                batch_ext._ACTIVE_CONTEXT = context
                structure_result = SimpleNamespace(
                    structures=[
                        SimpleNamespace(
                            local_id=1,
                            source_shared_template="object/building/test/shared_cave.iff",
                            custom_interior_layout="interiorlayout/worldbuilder/parent/structure_1.ilf",
                            interior_local_ids=[],
                        )
                    ]
                )
                replacements = {
                    "interiorlayout/worldbuilder/parent/structure_1.ilf": b"BASE|"
                }
                resolver = SimpleNamespace(read=lambda _path: b"asset")
                batch_ext._compose_for_project(
                    wb, resolver, "parent", replacements, structure_result
                )
                self.assertEqual(
                    replacements["interiorlayout/worldbuilder/parent/structure_1.ilf"],
                    b"BASE|9:r2|7:r2|",
                )
                self.assertEqual(
                    [row["contributor_publish_id"] for row in structure_result.external_contributions],
                    ["a_child", "z_child"],
                )

            self._with_fake_ilf_api(run)

    def test_external_room_identity_mismatch_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            parent = approved("parent", make_parent(), root)
            child_project = make_child("child")
            child_project.external_interiors[0].room_name = "old_room"
            child = approved("child", child_project, root)
            context = batch.build_extension_context([parent, child])

            def run():
                batch_ext._ACTIVE_CONTEXT = context
                structure_result = SimpleNamespace(
                    structures=[
                        SimpleNamespace(
                            local_id=1,
                            source_shared_template="object/building/test/shared_cave.iff",
                            custom_interior_layout="interiorlayout/worldbuilder/parent/structure_1.ilf",
                            interior_local_ids=[],
                        )
                    ]
                )
                replacements = {
                    "interiorlayout/worldbuilder/parent/structure_1.ilf": b"BASE|"
                }
                resolver = SimpleNamespace(read=lambda _path: b"asset")
                with self.assertRaisesRegex(wb.WorldBuilderError, "does not exactly match"):
                    batch_ext._compose_for_project(
                        wb, resolver, "parent", replacements, structure_result
                    )

            self._with_fake_ilf_api(run)


class DependencyGraphTests(unittest.TestCase):
    def test_missing_parent_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            child = make_child("child", "missing_parent")
            with self.assertRaisesRegex(wb.WorldBuilderError, "not enabled in the approved publish set"):
                batch.build_extension_context([approved("child", child, root)])

    def test_wrong_planet_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            parent = make_parent(planet="lok")
            child = make_child("child", planet="naboo")
            with self.assertRaisesRegex(wb.WorldBuilderError, "Cross-planet structure extensions"):
                batch.build_extension_context(
                    [approved("parent", parent, root), approved("child", child, root)]
                )

    def test_missing_parent_structure_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            parent = wb.Project(version=2, name="parent", planet="lok", structures=[structure(2)])
            child = make_child("child")
            with self.assertRaisesRegex(wb.WorldBuilderError, "STRUCTURE record no longer exists"):
                batch.build_extension_context(
                    [approved("parent", parent, root), approved("child", child, root)]
                )

    def test_dependency_cycle_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            a = make_parent(name="a")
            b = make_parent(name="b")
            a.version = wb.WBP_EXTENSION_VERSION
            b.version = wb.WBP_EXTENSION_VERSION
            a.extensions = [wb.ProjectExtension("b", 1)]
            a.external_interiors = []
            b.extensions = [wb.ProjectExtension("a", 1)]
            b.external_interiors = []
            with self.assertRaisesRegex(wb.WorldBuilderError, "dependency cycle"):
                batch.build_extension_context([approved("a", a, root), approved("b", b, root)])

    def test_contribution_order_is_deterministic(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            parent = approved("parent", make_parent(), root)
            z_child = approved("z_child", make_child("z_child", local_id=7), root)
            a_child = approved("a_child", make_child("a_child", local_id=9), root)

            context_a = batch.build_extension_context([z_child, parent, a_child])
            context_b = batch.build_extension_context([a_child, z_child, parent])
            key = ("parent", 1)
            order_a = [
                (row.contributor_publish_id, row.interior.local_id)
                for row in context_a.contributions[key]
            ]
            order_b = [
                (row.contributor_publish_id, row.interior.local_id)
                for row in context_b.contributions[key]
            ]
            self.assertEqual(order_a, [("a_child", 9), ("z_child", 7)])
            self.assertEqual(order_a, order_b)


if __name__ == "__main__":
    unittest.main(verbosity=2)
