"""Static Academy checks; cannot replace Roblox Studio or Luau execution."""
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

    def test_manifest(self):
        self.assertEqual(validate_project(ROOT / "academy.project.json"), [])
        spec = json.loads(self.load("academy.project.json"))["tree"]
        self.assertEqual(set(spec["ServerScriptService"]), {"$className", "SymbiontRules", "SymbiontWorld"})
        self.assertIn("SymbiontHUD", spec["StarterPlayer"]["StarterPlayerScripts"])

    def test_scenarios_and_actions(self):
        content = self.load("src/academy/shared/AcademyContent.lua")
        for key in ("water", "bridge", "council"):
            self.assertIn("    " + key + " = {", content)
        for key in ("activate", "open", "meeting", "petition", "audit"):
            self.assertIn("            " + key + " = {", content)
        self.assertIn('AcademyContent.order = {"water", "bridge", "council"}', content)

    def test_server_authority(self):
        world = self.load("src/academy/server/SymbiontWorld.server.lua")
        client = self.load("src/academy/client/SymbiontHUD.client.lua")
        rules = self.load("src/academy/server/SymbiontRules.lua")
        for token in ("prompt.Triggered:Connect", "throttled(player)",
                      "(root.Position - part.Position).Magnitude <= maxDistance",
                      "Rules.apply(state, levelId, actionId, player.UserId)",
                      "getState.OnServerInvoke"):
            self.assertIn(token, world)
        self.assertIn("Rules.isUnlocked", rules)
        self.assertIn("action.requires", rules)
        self.assertNotIn("FireServer(", client)
        self.assertNotIn("DataStoreService", world + client + rules)

    def test_chess_remains_separate(self):
        main = json.loads(self.load("default.project.json"))["tree"]
        academy = json.loads(self.load("academy.project.json"))["tree"]
        self.assertIn("ChessArena", main["ServerScriptService"])
        self.assertNotIn("ChessArena", academy["ServerScriptService"])


if __name__ == "__main__":
    unittest.main()
