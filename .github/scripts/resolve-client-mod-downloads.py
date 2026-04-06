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


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: resolve-client-mod-downloads.py <lockfile-path> <output-list-path>")
        return 1

    lock_path = pathlib.Path(sys.argv[1])
    out_path = pathlib.Path(sys.argv[2])

    if not lock_path.is_file():
        print(f"Lockfile not found: {lock_path}")
        return 1

    lock = json.loads(lock_path.read_text(encoding="utf-8"))
    projects = lock.get("projects", [])

    side_allowed = {"BOTH", "CLIENT"}
    priority = {"curseforge": 0, "modrinth": 1}

    lines: list[str] = []

    for project in projects:
        project_type = str(project.get("type", "")).upper()
        if project_type != "MOD":
            continue

        side = str(project.get("side", "")).upper()
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
