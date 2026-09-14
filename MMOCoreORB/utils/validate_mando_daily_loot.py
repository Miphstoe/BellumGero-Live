"""Static validation of the FOB daily reward data; does not emulate Core3."""
from pathlib import Path
import re

SCRIPTS = Path(__file__).resolve().parents[1] / "bin/scripts"
LOOT = SCRIPTS / "loot"
EXPECTED = [
    [50000, 25000, 10000, 50000, 10000, 50000, 1500000, 8305000],
    [100000, 50000, 25000, 100000, 25000, 100000, 1800000, 7800000],
    [200000, 100000, 50000, 150000, 50000, 200000, 2100000, 7150000],
    [400000, 200000, 75000, 200000, 100000, 300000, 2400000, 6325000],
    [800000, 400000, 100000, 300000, 200000, 400000, 2700000, 5100000],
]
MANDO_DECOR_WEIGHTS = [
    {"mando_clan_banner": 100000, "mando_clan_painting": 100000,
     "mando_holo_emblem": 25000, "mando_helmet_holo": 25000},
    {"mando_clan_banner": 200000, "mando_clan_painting": 200000,
     "mando_holo_emblem": 50000, "mando_helmet_holo": 50000},
    {"mando_clan_banner": 300000, "mando_clan_painting": 300000,
     "mando_holo_emblem": 75000, "mando_helmet_holo": 75000},
    {"mando_clan_banner": 500000, "mando_clan_painting": 500000,
     "mando_holo_emblem": 100000, "mando_helmet_holo": 100000},
    {"mando_clan_banner": 750000, "mando_clan_painting": 750000,
     "mando_holo_emblem": 200000, "mando_helmet_holo": 200000},
]
ENTRY = re.compile(r'itemTemplate = "([^"]+)",\s*weight = (\d+)')


def main():
    # Only count item definitions whose source is included in the item registry.
    registered = set()
    registry = (LOOT / "items.lua").read_text()
    for relative in re.findall(r'^includeFile\("([^"]+)"\)', registry, re.M):
        source = LOOT / relative
        if source.is_file():
            registered.update(re.findall(r'addLootItemTemplate\("([^"]+)"', source.read_text()))
    assert registry.count('includeFile("items/bellum/mando_daily_weapons.lua")') == 1
    group_registry = (LOOT / "groups.lua").read_text()
    previous = {}
    for tier, expected in enumerate(EXPECTED, 1):
        name = f"mando_daily_bounty_tier{tier}_loot"
        assert f'includeFile("groups/bellum/{name}.lua")' in group_registry
        source = (LOOT / f"groups/bellum/{name}.lua").read_text()
        assert f'addLootGroupTemplate("{name}", {name})' in source
        entries = [(name, int(weight)) for name, weight in ENTRY.findall(source)]
        assert len(dict(entries)) == len(entries), f"Tier {tier}: duplicate item"
        assert sum(weight for _, weight in entries) == 10000000
        assert all(weight > 0 and name in registered for name, weight in entries)
        assert all(name != "krayt_dragon_tissue_epic" for name, _ in entries)
        sections = re.split(r'\t\t-- [^\n]+\n', source)[1:]
        assert len(sections) == len(expected)
        for index, (section, total) in enumerate(zip(sections, expected)):
            items = [(name, int(weight)) for name, weight in ENTRY.findall(section)]
            assert sum(weight for _, weight in items) == total, (tier, index)
            if index < 7:
                for name, weight in items:
                    assert weight > previous.get(name, 0), (tier, name)
                    previous[name] = weight
        assert len(ENTRY.findall(sections[0])) == 20
        assert len(ENTRY.findall(sections[1])) == 6
        assert len(ENTRY.findall(sections[2])) == 9
        assert len(ENTRY.findall(sections[3])) == 5
        decor = {name: int(weight) for name, weight in ENTRY.findall(sections[7])}
        for name, weight in MANDO_DECOR_WEIGHTS[tier - 1].items():
            assert decor.get(name) == weight, (tier, name, decor.get(name))
        print(f"Tier {tier}: total 10,000,000; all category odds and registrations valid")

    weapons = (LOOT / "items/bellum/mando_daily_weapons.lua").read_text()
    object_sources = list((SCRIPTS / "object/weapon").rglob("*.lua"))
    object_text = "\n".join(path.read_text() for path in object_sources)
    blocks = re.findall(r'(mando_daily_\w+) = \{(.*?)\n\}\naddLootItemTemplate\("\1", \1\)', weapons, re.S)
    assert len(blocks) == 9
    required = {"mindamage", "maxdamage", "attackspeed", "hitpoints", "attackhealthcost", "attackactioncost", "attackmindcost"}
    for name, block in blocks:
        template = re.search(r'directObjectTemplate = "([^"]+)"', block)[1]
        assert f'"{template}")' in object_text, template
        attributes = re.findall(r'\{"([^"]+)",([^,]+),([^,]+),(\d+)\}', block)
        stats = {key: (float(low), float(high)) for key, low, high, _ in attributes}
        assert len(stats) == len(attributes), name
        assert required <= stats.keys(), name
        assert all(min(stats[key]) > 0 for key in ("mindamage", "maxdamage", "attackspeed", "hitpoints")), name
        assert max(stats["mindamage"]) <= min(stats["maxdamage"]), name
    helper = (SCRIPTS / "screenplays/bellum/bounty_camp_theater_helpers.lua").read_text()
    assert "You received a schematic" not in helper
    assert "You received a reward from the mark's belongings." in helper
    print("Nine finished weapon definitions and generic reward message valid")


if __name__ == "__main__":
    main()
