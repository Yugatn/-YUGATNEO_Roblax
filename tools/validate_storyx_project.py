#!/usr/bin/env python3
"""Validate Rojo file maps and require() dependencies without launching Roblox Studio.

This is a static integrity check, NOT a Luau parser or play-test.
"""
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"default.project.json"
REQUIRE=re.compile(r'script\.Parent:WaitForChild\(\s*["\']([^"\']+)["\']\s*\)')
errors=[]
m=json.loads(MANIFEST.read_text(encoding="utf-8"))
tree=m["tree"]
server=tree["ServerScriptService"]
clients=tree["StarterPlayer"]["StarterPlayerScripts"]
all_files={}
def walk(node,logical):
    if isinstance(node,dict):
        if "$path" in node:
            path=ROOT/node["$path"]
            if logical in all_files: errors.append(f"Duplicate logical name: {logical}")
            all_files[logical]=path
            if not path.is_file(): errors.append(f"Missing file: {logical} -> {path}")
            if path.suffix!=".lua": errors.append(f"Not a Luau source: {path}")
        for key,value in node.items():
            if not key.startswith("$"): walk(value,logical+"."+key)
walk(tree,"DataModel")
server_keys={k for k in server if not k.startswith("$")}
client_keys={k for k in clients if not k.startswith("$")}
for name in sorted(server_keys):
    data=server[name]
    if "$path" not in data: continue
    source=ROOT/data["$path"]
    if not source.is_file(): continue
    content=source.read_text(encoding="utf-8")
    for dependency in REQUIRE.findall(content):
        if dependency not in server_keys:
            errors.append(f"{name} requires ServerScriptService.{dependency} but manifest omits it")
for name in sorted(client_keys):
    data=clients[name]
    if "$path" not in data: continue
    source=ROOT/data["$path"]
    if not source.is_file(): continue
    if not source.name.endswith(".client.lua"):
        errors.append(f"Client {name} needs *.client.lua: {source}")
for required in (
    "WaveDefense","DefenseTactics","DefenseNavigation","DefenseRules",
    "WorldRewards","InfectionTag","NeonGridWorld","LightCycleEngine",
):
    if required not in server_keys: errors.append(f"Expected ServerScriptService module missing: {required}")
print(f"Rojo entries: {len(all_files)} / server: {len(server_keys)} / client: {len(client_keys)}")
if errors:
    for error in errors: print("ERROR:",error)
    raise SystemExit(1)
print("PASS: All mapped sources exist and server-side parent modules are present.")
print("NOTE: This does not validate Luau syntax, geometry, AI, RemoteEvent security or DataStore behavior.")
