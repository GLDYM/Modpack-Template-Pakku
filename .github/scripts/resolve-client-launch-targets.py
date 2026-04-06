#!/usr/bin/env python3
import json
import pathlib
import sys


def unique_preserve_order(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if not item or item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: resolve-client-launch-targets.py <lockfile-path> <output-path>")
        return 1

    lock_path = pathlib.Path(sys.argv[1])
    out_path = pathlib.Path(sys.argv[2])

    if not lock_path.is_file():
        print(f"Lockfile not found: {lock_path}")
        return 1

    lock = json.loads(lock_path.read_text(encoding="utf-8"))
    mc_version = str((lock.get("mc_versions") or [""])[0]).strip()
    loaders = lock.get("loaders", {})

    if not mc_version:
        print("Missing mc_versions in lockfile")
        return 1

    targets: list[str] = []

    if "neoforge" in loaders:
        loader_ver = str(loaders["neoforge"]).strip()
        candidates = [
            # Common forms used by different portablemc releases.
            f"neoforge:{mc_version}",
            f"neoforge:{loader_ver}",
            f"neoforge:{mc_version}:{loader_ver}",
            "neoforge",
        ]

        # Some lockfiles include prerelease suffixes that launcher resolvers may not accept.
        loader_no_suffix = loader_ver.split("-", 1)[0]
        if loader_no_suffix != loader_ver:
            candidates.extend(
                [
                    f"neoforge:{loader_no_suffix}",
                    f"neoforge:{mc_version}:{loader_no_suffix}",
                ]
            )

        # If loader version starts with MC version, also try "mc:loaderPart" patterns.
        # Example: mc=26.1.1, loader=26.1.1.6-beta -> loader_part=6-beta.
        prefix = f"{mc_version}."
        if loader_ver.startswith(prefix):
            loader_part = loader_ver[len(prefix):]
            loader_part_no_suffix = loader_part.split("-", 1)[0]
            candidates.extend(
                [
                    f"neoforge:{mc_version}:{loader_part}",
                    f"neoforge:{mc_version}:{loader_part_no_suffix}",
                    f"neoforge:{mc_version}-{loader_part}",
                ]
            )

        targets = unique_preserve_order(candidates)
    elif "forge" in loaders:
        loader_ver = str(loaders["forge"]).strip()
        targets = unique_preserve_order([
            f"forge:{mc_version}",
            f"forge:{mc_version}:{loader_ver}",
            f"forge:{loader_ver}",
        ])
    elif "fabric" in loaders:
        loader_ver = str(loaders["fabric"]).strip()
        targets = unique_preserve_order([
            f"fabric:{mc_version}",
            f"fabric:{mc_version}:{loader_ver}",
            "fabric",
        ])
    else:
        targets = [mc_version]

    # First line is MC version; following lines are portablemc target candidates.
    out_path.write_text("\n".join([mc_version, *targets]), encoding="utf-8")
    print(f"Resolved {len(targets)} launch target candidates")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
