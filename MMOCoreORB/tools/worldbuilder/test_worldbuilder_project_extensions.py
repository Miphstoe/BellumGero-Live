#!/usr/bin/env python3
"""Regression checks for Bellum Gero World Builder V1.9.8 project extensions.

These tests intentionally avoid TRE/IFF assets. They exercise the compatibility
surface that can be validated from project manifests alone: V1/V2 parsing,
V3 records, dependency graph safety, and deterministic contribution ordering.
"""

from __future__ import annotations

import tempfile
import unittest
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
