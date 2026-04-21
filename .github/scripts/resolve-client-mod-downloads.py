#!/usr/bin/env python3

'''
resolve-client-mod-downloads.py
Resolve client mods download URLs based on the lockfile.
If Portable MC adds their support of Curseforge modpack format,
this file is no longer needed.
'''

import json
import pathlib
import sys


def _read_side_overrides(pakku_path: pathlib.Path) -> dict[str, str]:
    """Read side overrides from pakku.json (projects.<slug>.side)."""
    if not pakku_path.is_file():
        return {}

    try:
        pakku = json.loads(pakku_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}

    projects = pakku.get("projects")
    if not isinstance(projects, dict):
        return {}

    overrides: dict[str, str] = {}
    for slug, config in projects.items():
        if not isinstance(slug, str) or not isinstance(config, dict):
            continue
        side = config.get("side")
        if isinstance(side, str) and side:
            overrides[slug] = side.upper()

    return overrides


def _get_project_slug(project: dict) -> str | None:
    slug = project.get("slug")
    if not isinstance(slug, dict):
        return None

    # Prefer modrinth slug first to match current pack configuration habits.
    preferred = slug.get("modrinth")
    if isinstance(preferred, str) and preferred:
        return preferred

    for value in slug.values():
        if isinstance(value, str) and value:
            return value

    return None


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: resolve-client-mod-downloads.py <lockfile-path> <pakku-json-path> <output-list-path>")
        return 1

    lock_path = pathlib.Path(sys.argv[1])
    pakku_path = pathlib.Path(sys.argv[2])
    out_path = pathlib.Path(sys.argv[3])

    if not lock_path.is_file():
        print(f"Lockfile not found: {lock_path}")
        return 1

    if not pakku_path.is_file():
        print(f"Pakku config not found: {pakku_path}")
        return 1

    lock = json.loads(lock_path.read_text(encoding="utf-8"))
    projects = lock.get("projects", [])
    side_overrides = _read_side_overrides(pakku_path)

    side_allowed = {"BOTH", "CLIENT"}
    priority = {"curseforge": 0, "modrinth": 1}

    lines: list[str] = []

    for project in projects:
        project_type = str(project.get("type", "")).upper()
        if project_type != "MOD":
            continue

        side = str(project.get("side", "BOTH")).upper()
        project_slug = _get_project_slug(project)
        if project_slug and project_slug in side_overrides:
            side = side_overrides[project_slug]
        if side not in side_allowed:
            continue

        files = project.get("files", [])
        candidates = [f for f in files if f.get("url")]
        if not candidates:
            continue

        candidates.sort(key=lambda f: priority.get(str(f.get("type", "")).lower(), 99))
        chosen = candidates[0]

        url = chosen.get("url")
        file_name = chosen.get("file_name")
        if not file_name:
            file_name = str(url).rstrip("/").split("/")[-1]

        sha1 = ""
        hashes = chosen.get("hashes")
        if isinstance(hashes, dict):
            sha1 = str(hashes.get("sha1", ""))

        lines.append("\t".join([str(url), str(file_name), sha1]))

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Resolved {len(lines)} client mod downloads")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
