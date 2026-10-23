#!/usr/bin/env python3
"""Validate Story X art handoff metadata against the Lua gallery catalog.

Static source check only. Roblox moderation, rights and rendering require review.
"""
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/"docs/STORY_X_GALLERY_ART_MANIFEST.json").read_text(encoding="utf-8"))
source=(root/"src/server/StoryXGalleryCatalog.lua").read_text(encoding="utf-8")
matches=re.findall(r'\bid="([a-z_]+)".*?\bimageAsset=(\d+)',source,re.S)
expected={name:int(asset) for name,asset in matches}
errors=[]
actual=manifest.get("entries",[])
if len(expected)!=10 or len(actual)!=10:
    errors.append("Expected 10 unique gallery entries in both Lua and manifest")
seen=set()
for item in actual:
    name=item.get("id")
    if name in seen: errors.append(f"Duplicate manifest scene {name}")
    seen.add(name)
    if name not in expected: errors.append(f"Manifest references nonexistent scene {name}")
    roblox_id=item.get("robloxImageAssetId")
    if not isinstance(roblox_id,int) or isinstance(roblox_id,bool) or roblox_id<0:
        errors.append(f"{name}: invalid Roblox asset ID")
    elif expected.get(name)!=roblox_id:
        errors.append(f"{name}: Lua imageAsset={expected.get(name)} differs from manifest={roblox_id}")
    if roblox_id:
        if item.get("rightsStatus")!="APPROVED":
            errors.append(f"{name}: nonzero asset requires approved rights review")
        if item.get("assetStatus")!="PUBLISHED_AND_MODERATED":
            errors.append(f"{name}: asset must pass Creator Dashboard moderation first")
        if not item.get("altText"):
            errors.append(f"{name}: altText required for published image")
for name in expected:
    if name not in seen: errors.append(f"Missing manifest entry: {name}")
if errors:
    for err in errors: print("FAIL:",err)
    raise SystemExit(1)
print(f"PASS: {len(expected)} gallery scenes match source catalog and rights manifest.")
print("NOTE: Placeholder assets are fine for CI; no asset rights or Roblox rendering verified.")
