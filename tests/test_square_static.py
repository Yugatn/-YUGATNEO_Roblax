"""Static integrity/security tests for isolated Four Square Roblox Place."""
import json
from pathlib import Path
import sys
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from validate_rojo_manifest import validate_project

class FourSquareStaticTests(unittest.TestCase):
    def read(self, path):
        return (ROOT/path).read_text(encoding="utf-8")

    def test_separate_rojo(self):
        self.assertEqual(validate_project(ROOT/"square.project.json"), [])
        main = json.loads(self.read("default.project.json"))["tree"]
        square = json.loads(self.read("square.project.json"))["tree"]
        self.assertIn("ChessArena", main["ServerScriptService"])
        self.assertNotIn("ChessArena", square["ServerScriptService"])
        self.assertEqual(set(square["ServerScriptService"]), {"$className","SquareGame","SquareRules"})
        self.assertIn("SquareHUD", square["StarterPlayer"]["StarterPlayerScripts"])

    def test_mandatory_rules(self):
        rules=self.read("src/square/server/SquareRules.lua")
        config=self.read("src/square/shared/SquareConfig.lua")
        for snippet in ('state.bounceCount >= 3','state.bounceCount >= 2',
                        '"early_foot"','state.lastHit == "head"',
                        'state.missed[seat] >= 5','zone == -1',
                        'state.isServe = (kind == "serve")'):
            self.assertIn(snippet, rules)
        self.assertIn("centerHalf = 4", config)
        self.assertIn("local diagonal =", rules)

    def test_server_authority(self):
        world=self.read("src/square/server/SquareGame.server.lua")
        ui=self.read("src/square/client/SquareHUD.client.lua")
        for snippet in ("RunService.Heartbeat:Connect","actionRemote.OnServerEvent:Connect",
                        "Rules.hit(state, seat, kind, target)","Config.zone(ground.X, ground.Z)",
                        "eligibleContact(player, seat, kind)","lastActionAt[player.UserId]",
                        "head.Position-ball.Position", "state.lastBounceZone == seat"):
            self.assertIn(snippet, world)
        for snippet in ("strikeRemote:FireServer(kind,selectedTarget)","Enum.KeyCode.H",
                        "Enum.KeyCode.F","Enum.KeyCode.P","targetButtons",
                        "CameraType.Scriptable"):
            self.assertIn(snippet, ui)
        self.assertNotIn("DataStoreService", world+ui)
        self.assertNotIn("LoadStringEnabled", world+ui)

if __name__=="__main__":
    unittest.main()
