"""Tests for local static Rojo manifest validation, no Roblox engine required."""
import json
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from validate_rojo_manifest import validate_project


class ManifestValidationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "src/server").mkdir(parents=True)
        (self.root / "src/client").mkdir(parents=True)
        (self.root / "src/server/Chess.server.lua").write_text("print('ok')")
        (self.root / "src/client/Client.client.lua").write_text("print('ok')")

    def write(self, mapping):
        f = self.root / "default.project.json"
        f.write_text(json.dumps({"name": "Test", "tree": mapping}))
        return f

    def test_valid_project(self):
        p = self.write({"$className": "DataModel", "ServerScriptService":
            {"Chess": {"$path": "src/server/Chess.server.lua"}},
            "StarterPlayer": {"StarterPlayerScripts":
            {"Client": {"$path": "src/client/Client.client.lua"}}}})
        self.assertEqual(validate_project(p), [])

    def test_missing_source_fails(self):
        p = self.write({"ServerScriptService":
            {"Missing": {"$path": "src/server/Missing.server.lua"}}})
        self.assertTrue(any("missing" in s for s in validate_project(p)))

    def test_parent_traversal_fails(self):
        p = self.write({"ServerScriptService":
            {"Escape": {"$path": "../private/secret.server.lua"}}})
        self.assertTrue(any("traversal" in s for s in validate_project(p)))

    def test_duplicate_source_fails(self):
        p = self.write({"ServerScriptService":
            {"A": {"$path": "src/server/Chess.server.lua"},
             "B": {"$path": "src/server/Chess.server.lua"}}})
        self.assertTrue(any("duplicate" in s for s in validate_project(p)))

    def test_invalid_service_fails(self):
        p = self.write({"StarterPlayer": {"StarterPlayerScripts":
            {"Server": {"$path": "src/server/Chess.server.lua"}}}})
        self.assertTrue(any("ServerScriptService" in s for s in validate_project(p)))

    def test_empty_mapping_fails(self):
        self.assertTrue(any("no mapped" in s for s in validate_project(self.write({}))))

    def test_malformed_json_fails(self):
        f = self.root / "bad.project.json"
        f.write_text("{")
        self.assertTrue(any("parse" in s for s in validate_project(f)))


if __name__ == "__main__":
    unittest.main()
