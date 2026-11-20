"""Static Academy contract checks; Roblox Studio playtests are still required."""
from pathlib import Path
import json
import unittest
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from validate_rojo_manifest import validate_project


class AcademyStaticTests(unittest.TestCase):
    def load(self, rel):
        return (ROOT / rel).read_text(encoding="utf-8")

    def test_manifest_maps_separate_place(self):
        self.assertEqual(validate_project(ROOT / "academy.project.json"), [])
        spec = json.loads(self.load("academy.project.json"))["tree"]
        self.assertEqual(
            set(spec["ServerScriptService"]),
            {"$className", "SymbiontRules", "SymbiontRooms", "SymbiontWorld"},
        )
        self.assertIn("SymbiontHUD", spec["StarterPlayer"]["StarterPlayerScripts"])

    def test_three_scenarios_and_alternative_resolution(self):
        content = self.load("src/academy/shared/AcademyContent.lua")
        for level_id in ("water", "bridge", "council"):
            self.assertIn("    " + level_id + " = {", content)
        for action_id in ("activate", "open", "meeting", "petition", "audit"):
            self.assertIn("            " + action_id + " = {", content)
        self.assertIn('AcademyContent.order = {"water", "bridge", "council"}', content)

    def test_server_authority_and_isolation(self):
        world = self.load("src/academy/server/SymbiontWorld.server.lua")
        client = self.load("src/academy/client/SymbiontHUD.client.lua")
        rules = self.load("src/academy/server/SymbiontRules.lua")
        rooms = self.load("src/academy/server/SymbiontRooms.lua")
        for token in (
            "prompt.Triggered:Connect",
            "(root.Position - part.Position).Magnitude <= maxDistance",
            "Rooms.apply(registry, player.UserId, roomId, levelId, actionId)",
            "Rooms.roomOf(registry, player.UserId)",
            "getState.OnServerInvoke",
            "if not prompt.Enabled",
            "confirmations[player.UserId]",
            "originFor(roomId)",
        ):
            self.assertIn(token, world)
        for token in (
            "registry.playerRoom[userId] ~= roomId",
            "#room.members >= registry.maxPlayers",
            "room.leader ~= userId",
            "room.state = Rules.newState()",
            "registry.rooms[roomId] = nil",
            "registry.sequence += 1",
        ):
            self.assertIn(token, rooms)
        self.assertIn("Rules.isUnlocked", rules)
        self.assertIn("action.requires", rules)
        self.assertNotIn("FireServer(", client)
        self.assertNotIn("DataStoreService", world + client + rules + rooms)

    def test_team_packets_contain_no_member_identifiers(self):
        rooms = self.load("src/academy/server/SymbiontRooms.lua")
        source = rooms.split("function Rooms.snapshot(", 1)[1]
        self.assertNotIn("leaderId =", source)
        self.assertNotIn("members = room.members", source)
        self.assertIn("isLeader = room.leader == userId", source)
        self.assertIn("members = #room.members", source)

    def test_chess_remains_untouched(self):
        main = json.loads(self.load("default.project.json"))["tree"]
        academy = json.loads(self.load("academy.project.json"))["tree"]
        self.assertIn("ChessArena", main["ServerScriptService"])
        self.assertNotIn("ChessArena", academy["ServerScriptService"])


if __name__ == "__main__":
    unittest.main()
