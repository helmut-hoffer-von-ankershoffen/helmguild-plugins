#!/usr/bin/env python3
"""Validate the helmguild-plugins marketplace catalog + every plugin + every SKILL.md.

Checks (loud failures, exit 1 on any issue):

* `.claude-plugin/marketplace.json` exists and parses; every plugin entry's
  `source` resolves to a plugin folder that actually exists.
* Each plugin under `plugins/<name>/` has `.claude-plugin/plugin.json` with
  `name`, `description`, `version`; `name` matches the folder name; license
  is the Helmguild Mentoring License v1.0 (`LicenseRef-helmguild-mentoring-1.0`).
* Each plugin has at least one SKILL.md under `skills/<id>/`.
* Each `SKILL.md` has valid YAML frontmatter with required `name` (matching
  its folder), `description` (1-1024 chars). `metadata.order` is unique
  per plugin.
* Optional: `.mcp.json` if present must parse.

Loud-by-design — every problem is reported with the file path so reviewers
can fix in one pass.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    import yaml  # type: ignore[import-not-found]
except ImportError:
    print("::error::PyYAML missing. Run `pip install pyyaml` first.", file=sys.stderr)
    sys.exit(2)

REPO = Path(__file__).resolve().parents[2]
PLUGINS_DIR = REPO / "plugins"
MARKETPLACE = REPO / ".claude-plugin" / "marketplace.json"

NAME_RE = re.compile(r"^[a-z][a-z0-9-]*$")

errors: list[str] = []


def err(path: Path, msg: str) -> None:
    """Record an error with a file-relative path."""
    rel = path.relative_to(REPO)
    errors.append(f"{rel}: {msg}")


def parse_frontmatter(body: str, path: Path) -> dict | None:
    """Pull the YAML frontmatter out of a SKILL.md body.

    Args:
        body: Full file content.
        path: Source path for error reporting.

    Returns:
        Parsed frontmatter dict, or ``None`` when malformed (error is
        already recorded against ``path``).
    """
    if not body.startswith("---\n"):
        err(path, "missing leading `---` frontmatter delimiter")
        return None
    end = body.find("\n---\n", 4)
    if end < 0:
        err(path, "missing closing `---` frontmatter delimiter")
        return None
    try:
        fm = yaml.safe_load(body[4:end])
    except yaml.YAMLError as e:
        err(path, f"frontmatter YAML invalid: {e}")
        return None
    if not isinstance(fm, dict):
        err(path, "frontmatter must be a YAML mapping")
        return None
    return fm


def check_skill(skill_dir: Path, plugin_name: str, seen_orders: set[int]) -> None:
    """Validate one SKILL.md folder."""
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        err(skill_dir, "missing SKILL.md")
        return
    fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"), skill_md)
    if not fm:
        return
    name = fm.get("name")
    if not isinstance(name, str) or not NAME_RE.match(name) or not (1 <= len(name) <= 64):
        err(skill_md, f"`name` invalid (got {name!r}); must be 1-64 chars, [a-z0-9-], start with letter")
    elif name != skill_dir.name:
        err(skill_md, f"`name` ({name!r}) must match parent dir ({skill_dir.name!r}) per the AgentSkills spec")
    desc = fm.get("description")
    if not isinstance(desc, str) or not (1 <= len(desc) <= 1024):
        err(skill_md, "`description` missing or wrong length (must be 1-1024 chars)")
    expected_license = "LicenseRef-helmguild-mentoring-1.0"
    skill_license = fm.get("license")
    if skill_license != expected_license:
        err(skill_md, f"`license` is {skill_license!r}; expected {expected_license!r}")
    metadata = fm.get("metadata") or {}
    if not isinstance(metadata, dict):
        err(skill_md, "`metadata` must be a YAML mapping")
        return
    order = metadata.get("order")
    if order is not None:
        if not isinstance(order, int):
            err(skill_md, "`metadata.order` must be an integer")
        elif order in seen_orders:
            err(skill_md, f"`metadata.order` {order} duplicated in plugin {plugin_name!r}")
        else:
            seen_orders.add(order)


def check_plugin(plugin_dir: Path) -> str | None:
    """Validate one plugin folder; return its declared name or ``None`` on error."""
    manifest_path = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest_path.is_file():
        err(plugin_dir, "missing .claude-plugin/plugin.json")
        return None
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        err(manifest_path, f"invalid JSON: {e}")
        return None
    name = manifest.get("name")
    if not isinstance(name, str) or not NAME_RE.match(name):
        err(manifest_path, f"`name` invalid (got {name!r})")
        return None
    if name != plugin_dir.name:
        err(manifest_path, f"`name` ({name!r}) must match folder name ({plugin_dir.name!r})")
    if not manifest.get("description"):
        err(manifest_path, "`description` missing")
    if not manifest.get("version"):
        err(manifest_path, "`version` missing")

    # SKILL.md folder discovery
    skills_dir = plugin_dir / "skills"
    if not skills_dir.is_dir():
        err(plugin_dir, "no `skills/` directory")
        return name
    skill_folders = [p for p in sorted(skills_dir.iterdir()) if p.is_dir()]
    if not skill_folders:
        err(skills_dir, "no SKILL.md folders found")
    seen_orders: set[int] = set()
    for sk in skill_folders:
        check_skill(sk, name, seen_orders)

    # Optional .mcp.json — verify it parses if present
    mcp = plugin_dir / ".mcp.json"
    if mcp.is_file():
        try:
            json.loads(mcp.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            err(mcp, f"invalid JSON: {e}")

    # Per-plugin LICENSE.md + plugin.json license field must match the
    # marketplace's Helmguild Mentoring License v1.0.
    license_md = plugin_dir / "LICENSE.md"
    if not license_md.is_file():
        err(plugin_dir, "missing LICENSE.md")
    expected_license = "LicenseRef-helmguild-mentoring-1.0"
    plugin_license = manifest.get("license")
    if plugin_license != expected_license:
        err(manifest_path, f"plugin.json license={plugin_license!r}; expected {expected_license!r}")

    # NOTE on `commercial`: Claude Code's plugin.json schema rejects
    # custom top-level keys (including `commercial` and `metadata`).
    # The commercial flag is therefore carried on the marketplace.json
    # side only — both at `metadata.commercial` and on each plugin
    # entry — and enforced in `main()` below. plugin.json stays clean.

    # Every bundled script (under scripts/ or mcp-server/) must have a
    # matching test under tests/test-<dir>-<stem>.{sh,mjs}. Catches the
    # class of regression where a plugin ships a helper with no proof
    # it works. (Helmut, 2026-05-14.)
    for src_dir, expected_ext in (("scripts", ".sh"), ("mcp-server", ".mjs")):
        dir_path = plugin_dir / src_dir
        if not dir_path.is_dir():
            continue
        for script in sorted(dir_path.iterdir()):
            if not script.is_file() or not script.suffix == expected_ext:
                continue
            test_ext = ".sh" if expected_ext == ".sh" else ".mjs"
            test_path = plugin_dir / "tests" / f"test-{src_dir}-{script.stem}{test_ext}"
            if not test_path.is_file():
                err(
                    script,
                    f"bundled script has no matching test (expected {test_path.relative_to(plugin_dir)})",
                )
                continue
            # Tests must be executable so the CI runner can spawn them
            # without an extra `chmod +x` step.
            mode = test_path.stat().st_mode
            if not (mode & 0o100):
                err(test_path, "test must be executable (chmod +x)")

    return name


def main() -> int:
    """Run every check; return process exit code."""
    if not MARKETPLACE.is_file():
        err(MARKETPLACE, "missing")
        print_errors()
        return 1
    try:
        marketplace = json.loads(MARKETPLACE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        err(MARKETPLACE, f"invalid JSON: {e}")
        print_errors()
        return 1
    if not marketplace.get("name"):
        err(MARKETPLACE, "`name` missing")
    if not marketplace.get("owner"):
        err(MARKETPLACE, "`owner` missing")
    # This is the PRIVATE / commercial marketplace.
    #
    # Claude Code's marketplace.json schema rejects custom keys on the
    # per-plugin entries — so the `commercial` flag lives ONLY in the
    # top-level `metadata` block. All plugins in this marketplace
    # inherit `metadata.commercial: true` (and `metadata.distribution:
    # "private"`); the ammp-mcp loader reads from there.
    md = marketplace.get("metadata") or {}
    if md.get("commercial") is not True:
        err(MARKETPLACE, "`metadata.commercial: true` required in this private marketplace")
    if md.get("distribution") != "private":
        err(MARKETPLACE, "`metadata.distribution: \"private\"` required in this marketplace")
    listed_plugins = {p["name"] for p in marketplace.get("plugins", []) if isinstance(p, dict) and p.get("name")}

    discovered: set[str] = set()
    if PLUGINS_DIR.is_dir():
        for plugin_dir in sorted(PLUGINS_DIR.iterdir()):
            if not plugin_dir.is_dir():
                continue
            name = check_plugin(plugin_dir)
            if name:
                discovered.add(name)
    # Cross-check: every plugin listed in the marketplace must exist on disk.
    missing_on_disk = listed_plugins - discovered
    extra_on_disk = discovered - listed_plugins
    for m in sorted(missing_on_disk):
        err(MARKETPLACE, f"plugin {m!r} listed but no folder under plugins/")
    for x in sorted(extra_on_disk):
        err(PLUGINS_DIR / x, "plugin folder exists but not listed in marketplace.json")

    if errors:
        print_errors()
        return 1
    print(f"OK — {len(discovered)} plugins, marketplace + frontmatter clean.")
    return 0


def print_errors() -> None:
    """Emit every recorded error in GitHub-Actions style."""
    print(f"::error::{len(errors)} validation error(s):", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)


if __name__ == "__main__":
    sys.exit(main())
