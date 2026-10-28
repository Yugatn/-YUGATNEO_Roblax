#!/usr/bin/env python3
"""Static Rojo manifest integrity check (not a Roblox Studio gameplay test).

Usage: python3 tools/validate_rojo_manifest.py default.project.json [other.project.json]
Uses the local checkout only. Rejects missing, unsafe, aliased or duplicate source paths.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


def validate_project(project_file: Path) -> list[str]:
    errors: list[str] = []
    project_file = project_file.resolve()
    root = project_file.parent

    try:
        spec: Any = json.loads(project_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        return [f"{project_file.name}: cannot read/parse JSON: {exc}"]

    if not isinstance(spec, dict) or not isinstance(spec.get("name"), str) or not isinstance(spec.get("tree"), dict):
        return [f"{project_file.name}: expected a Rojo project with name and tree"]

    mapped: dict[str, str] = {}
    paths: list[str] = []

    def walk(node: Any, section: tuple[str, ...]) -> None:
        if not isinstance(node, dict):
            errors.append(f"{'/'.join(section)}: expected object")
            return
        if "$path" in node:
            raw = node["$path"]
            if not isinstance(raw, str) or not raw or "\\" in raw:
                errors.append(f"{'/'.join(section)}: invalid $path")
                return
            rel = Path(raw)
            if rel.is_absolute() or ".." in rel.parts or not rel.parts:
                errors.append(f"{'/'.join(section)}: absolute/parent traversal not allowed ({raw})")
                return
            resolved = (root / rel).resolve()
            if not resolved.is_relative_to(root):
                errors.append(f"{'/'.join(section)}: symlink escapes repository ({raw})")
            elif not resolved.is_file():
                errors.append(f"{'/'.join(section)}: missing mapped file ({raw})")
            key = raw.casefold()
            if key in mapped:
                errors.append(f"{'/'.join(section)}: duplicate/aliased source {raw} at {mapped[key]}")
            else:
                mapped[key] = "/".join(section)
            paths.append(raw)
            if raw.endswith(".server.lua") and "ServerScriptService" not in section:
                errors.append(f"{raw}: .server.lua expected under ServerScriptService")
            if raw.endswith(".client.lua") and "StarterPlayerScripts" not in section:
                errors.append(f"{raw}: .client.lua expected under StarterPlayerScripts")
            if not (raw.endswith(".lua") or raw.endswith(".luau") or raw.endswith(".json")):
                errors.append(f"{raw}: unexpected extension in script project")
        for name, child in node.items():
            if name.startswith("$"):
                continue
            walk(child, (*section, name))

    walk(spec["tree"], ("tree",))
    if not paths:
        errors.append(f"{project_file.name}: no mapped source files")
    if errors:
        return errors
    print(f"PASS {project_file.name}: {len(paths)} valid source mappings")
    return []


def main(args: list[str]) -> int:
    if not args:
        print("Usage: validate_rojo_manifest.py default.project.json [more.project.json]", file=sys.stderr)
        return 2
    errors: list[str] = []
    for name in args:
        errors.extend(validate_project(Path(name)))
    for error in errors:
        print("FAIL " + error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
