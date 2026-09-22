#!/usr/bin/env python3
"""Execute the production Foundling quota block with lightweight engine doubles.

Run with Python 3 and g++ available. This isolates quota behavior; it does not
replace a server build or an in-game mission completion check.
"""

from pathlib import Path
import subprocess
import tempfile


SOURCE = Path(__file__).resolve().parents[1] / "src/server/zone/objects/mission/MissionObjectiveImplementation.cpp"


def quota_block():
    source = SOURCE.read_text(encoding="utf-8")
    start = source.index('if (ghost->getScreenPlayData("MandoWayOfLife", "foundling.planetCountingEnabled")')
    opening = source.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


HARNESS = r'''
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>
using uint32 = uint32_t;
struct String : std::string {
    using std::string::string;
    String(const std::string& s) : std::string(s) {}
    static String valueOf(int value) { return std::to_string(value); }
};
struct Integer { static int valueOf(const String& s) { return s.empty() ? 0 : std::stoi(s); } };
namespace MissionTypes {
    enum { BOUNTY, DESTROY, DELIVER, HUNTING, RECON, CRAFTING, SURVEY, ESCORT, ESCORT2ME, ESCORTTOCREATOR };
}
struct Ghost {
    std::map<std::string, String> data;
    String getScreenPlayData(const char*, const String& key) { return data[key]; }
    void setScreenPlayData(const char*, const String& key, const String& value) { data[key] = value; }
};
struct Zone { String planet; String getZoneName() { return planet; } };
struct Mission {
    uint32 type = MissionTypes::DESTROY;
    String planet;
    uint32 getTypeCRC() { return type; }
    String getStartPlanet() { return planet; }
};
struct Owner {
    std::vector<String> messages;
    void sendSystemMessage(const String& text) { messages.push_back(text); }
};
struct Exception {};
template<class T> using Reference = T;
struct LuaFunction {
    void operator<<(Owner*) {}
    void callFunction() {}
};
struct Lua { LuaFunction* createFunction(const char*, const char*, int) { return nullptr; } };
struct DirectorManager {
    static DirectorManager* instance() { static DirectorManager d; return &d; }
    Lua* getLuaInstance() { return nullptr; }
};
void complete(Ghost* ghost, Mission* mission, Zone* ownerZone, String missionId) {
    auto owner = std::make_shared<Owner>();
    // PRODUCTION_BLOCK
}
Ghost assignment(const String& planet) {
    Ghost g;
    g.data["foundling.planetCountingEnabled"] = "1";
    g.data["foundling.currentPlanet"] = planet;
    g.data["foundling.planetCompleted"] = "0";
    g.data["foundling.planetTarget"] = "24";
    return g;
}
int count(Ghost& g) { return Integer::valueOf(g.data["foundling.planetCompleted"]); }
int main() {
    const std::vector<String> planets = {"tatooine", "talus", "endor"};
    int checks = 0;
    for (const auto& assigned : planets) {
        for (const auto& origin : planets) {
            for (const auto& completion : planets) {
                for (uint32 type = MissionTypes::DESTROY; type <= MissionTypes::ESCORTTOCREATOR; ++type) {
                    auto g = assignment(assigned);
                    Mission m{type, origin}; Zone z{completion};
                    complete(&g, &m, &z, "1");
                    bool eligible = assigned == origin && assigned == completion;
                    assert(count(g) == (eligible ? 1 : 0));
                    assert((g.data["foundlingCounted_1"] == "1") == eligible);
                    ++checks;
                }
            }
        }
        auto g = assignment(assigned);
        Mission m{MissionTypes::DESTROY, assigned}; Zone z{assigned};
        complete(&g, &m, &z, "first");
        complete(&g, &m, &z, "first");
        assert(count(g) == 1); ++checks;
        for (int i = 2; i <= 24; ++i) complete(&g, &m, &z, String::valueOf(i));
        assert(count(g) == 24 && g.data["foundling.planetDone"] == "1"); ++checks;
        complete(&g, &m, &z, "extra");
        assert(count(g) == 24 && g.data["foundlingCounted_extra"] != "1"); ++checks;

        // Turning in changes the active planet and resets its quota, as advanceToPlanet does.
        String next = assigned == "talus" ? "endor" : "talus";
        g = assignment(next);
        complete(&g, &m, &z, "old-planet");
        assert(count(g) == 0); ++checks;
        m.planet = next; z.planet = next;
        complete(&g, &m, &z, "next-planet");
        assert(count(g) == 1); ++checks;

        g = assignment(assigned); m.planet = assigned; z.planet = assigned;
        g.data["foundling.planetCountingEnabled"] = "0";
        complete(&g, &m, &z, "inactive"); assert(count(g) == 0); ++checks;
        g = assignment(assigned);
        complete(&g, &m, nullptr, "no-zone"); assert(count(g) == 0); ++checks;
        g = assignment("");
        complete(&g, &m, &z, "no-assignment"); assert(count(g) == 0); ++checks;
        g = assignment(assigned); m.planet = "";
        complete(&g, &m, &z, "no-origin"); assert(count(g) == 0); ++checks;
        m.planet = assigned;
        for (uint32 excluded : {uint32(MissionTypes::BOUNTY), uint32(999)}) {
            m.type = excluded;
            complete(&g, &m, &z, "excluded"); assert(count(g) == 0); ++checks;
        }
    }
    std::cout << checks << " Foundling quota checks passed\n";
}
'''


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="foundling-credit-") as directory:
        source = Path(directory) / "test.cpp"
        binary = Path(directory) / "test"
        source.write_text(HARNESS.replace("// PRODUCTION_BLOCK", quota_block()), encoding="utf-8")
        subprocess.run(["g++", "-std=c++17", "-Wall", "-Wextra", "-Werror", str(source), "-o", str(binary)], check=True)
        subprocess.run([str(binary)], check=True)
