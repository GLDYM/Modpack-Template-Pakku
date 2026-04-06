#!/usr/bin/env python3
import json
import pathlib
import re
import sys


def load_key_value_properties(path: pathlib.Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith(";"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip()
    return data


def slugify(name: str) -> str:
    slug = re.sub(r"\s+", "", name)
    slug = re.sub(r"[^A-Za-z0-9._-]", "-", slug)
    slug = re.sub(r"-{2,}", "-", slug)
    slug = slug.strip("-")
    return slug or "modpack"


def resolve_java_version(mc_version: str) -> str:
    parts = mc_version.split(".")
    try:
        mc_major = int(parts[0]) if len(parts) > 0 and parts[0] else 1
    except ValueError:
        mc_major = 1
    try:
        mc_minor = int(parts[1]) if len(parts) > 1 and parts[1] else 0
    except ValueError:
        mc_minor = 0
    try:
        mc_patch = int(parts[2]) if len(parts) > 2 and parts[2] else 0
    except ValueError:
        mc_patch = 0

    # Legacy naming: 1.x.y
    # Modern naming: x.y.z (major starts from 26)
    java_version = "21"
    if mc_major == 1:
        if mc_minor >= 21:
            java_version = "21"
        elif mc_minor == 20 and mc_patch >= 5:
            java_version = "21"
        elif mc_minor >= 18:
            java_version = "17"
        elif mc_minor == 17:
            java_version = "16"
        else:
            java_version = "8"
    elif mc_major >= 26:
        java_version = "25"

    return java_version


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: resolve-build-meta.py <pakku.json> <pakku-lock.json> <install-config.properties>")
        return 1

    pakku_path = pathlib.Path(sys.argv[1])
    lock_path = pathlib.Path(sys.argv[2])
    install_config_path = pathlib.Path(sys.argv[3])

    if not pakku_path.is_file():
        print(f"pakku.json not found: {pakku_path}", file=sys.stderr)
        return 1
    if not lock_path.is_file():
        print(f"pakku-lock.json not found: {lock_path}", file=sys.stderr)
        return 1
    if not install_config_path.is_file():
        print(f"install-config.properties not found: {install_config_path}", file=sys.stderr)
        return 1
    if install_config_path.suffix.lower() != ".properties":
        print(f"install-config must be .properties: {install_config_path}", file=sys.stderr)
        return 1

    pakku = json.loads(pakku_path.read_text(encoding="utf-8"))
    lock = json.loads(lock_path.read_text(encoding="utf-8"))
    install_cfg = load_key_value_properties(install_config_path)

    pack_name = str(pakku.get("name") or "modpack")
    pack_version = str(pakku.get("version") or "0.0.0")
    pack_name_slug = slugify(pack_name)

    pakku_url = str(
        install_cfg.get("pakku_url")
        or "https://github.com/juraj-hrivnak/Pakku/releases/download/v1.3.2/pakku.jar"
    )

    mc_versions = lock.get("mc_versions") or []
    mc_version = str(mc_versions[0]) if mc_versions else "1.20.1"
    java_version = resolve_java_version(mc_version)

    print(f"pack_name={pack_name}")
    print(f"pack_version={pack_version}")
    print(f"pack_name_slug={pack_name_slug}")
    print(f"pakku_url={pakku_url}")
    print(f"mc_version={mc_version}")
    print(f"java_version={java_version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
