#!/usr/bin/env python3
"""Validate Special Skills marketplaces, plugins, skills, and shell helpers."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        fail(f"Cannot read valid JSON from {path.relative_to(ROOT)}: {error}")


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        fail(f"Missing YAML frontmatter in {path.relative_to(ROOT)}")

    values: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if not line.strip() or line.startswith((" ", "\t")):
            continue
        key, separator, value = line.partition(":")
        if separator:
            values[key.strip()] = value.strip().strip('"')
    return values


def marketplace_names() -> tuple[set[str], set[str]]:
    codex = read_json(ROOT / ".agents" / "plugins" / "marketplace.json")
    claude = read_json(ROOT / ".claude-plugin" / "marketplace.json")

    if codex.get("name") != "special-skills":
        fail("Codex marketplace name must be special-skills")
    if claude.get("name") != "special-skills":
        fail("Claude marketplace name must be special-skills")

    codex_names: set[str] = set()
    for entry in codex.get("plugins", []):
        name = entry.get("name")
        source = entry.get("source", {})
        if source.get("path") != f"./plugins/{name}":
            fail(f"Codex marketplace source mismatch for {name}")
        if entry.get("policy", {}).get("installation") != "AVAILABLE":
            fail(f"Codex plugin must be available: {name}")
        codex_names.add(name)

    claude_names: set[str] = set()
    for entry in claude.get("plugins", []):
        name = entry.get("name")
        if entry.get("source") != f"./plugins/{name}":
            fail(f"Claude marketplace source mismatch for {name}")
        claude_names.add(name)

    return codex_names, claude_names


def validate_markdown_links(skill_dir: Path) -> None:
    for markdown in skill_dir.rglob("*.md"):
        if markdown.relative_to(skill_dir).parts[0] == "assets":
            continue
        for raw_target in re.findall(r"\]\(([^)]+)\)", markdown.read_text()):
            if raw_target.startswith(("http://", "https://", "#")):
                continue
            target = raw_target.split("#", 1)[0]
            if target and not (markdown.parent / target).resolve().is_file():
                fail(
                    f"Broken skill reference: {markdown.relative_to(ROOT)} -> {raw_target}"
                )


def validate_plugin(plugin_dir: Path) -> None:
    name = plugin_dir.name
    codex = read_json(plugin_dir / ".codex-plugin" / "plugin.json")
    claude = read_json(plugin_dir / ".claude-plugin" / "plugin.json")
    if codex.get("name") != name or claude.get("name") != name:
        fail(f"Plugin manifest name does not match directory: {name}")
    if codex.get("skills") != "./skills/":
        fail(f"Codex skills path is invalid: {name}")
    if claude.get("license") != "MIT":
        fail(f"Claude plugin license must be MIT: {name}")

    skill_dirs = sorted(path for path in (plugin_dir / "skills").iterdir() if path.is_dir())
    if not skill_dirs:
        fail(f"Plugin has no skills: {name}")

    for skill_dir in skill_dirs:
        skill_file = skill_dir / "SKILL.md"
        if not skill_file.is_file():
            fail(f"Missing {skill_file.relative_to(ROOT)}")
        metadata = frontmatter(skill_file)
        if metadata.get("name") != skill_dir.name:
            fail(f"Skill name does not match directory: {skill_dir.relative_to(ROOT)}")
        if not metadata.get("description"):
            fail(f"Skill description is missing: {skill_file.relative_to(ROOT)}")
        if metadata.get("license") != "MIT":
            fail(f"Skill license must be MIT: {skill_file.relative_to(ROOT)}")
        if not (skill_dir / "agents" / "openai.yaml").is_file():
            fail(f"Missing Codex skill metadata: {skill_dir.relative_to(ROOT)}")
        validate_markdown_links(skill_dir)

    for shell_script in plugin_dir.rglob("*.sh"):
        result = subprocess.run(
            ["bash", "-n", str(shell_script)],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            fail(f"Shell syntax failed for {shell_script.relative_to(ROOT)}: {result.stderr}")


def main() -> None:
    codex_names, claude_names = marketplace_names()
    plugin_dirs = sorted(path for path in (ROOT / "plugins").iterdir() if path.is_dir())
    plugin_names = {path.name for path in plugin_dirs}

    if plugin_names != codex_names or plugin_names != claude_names:
        fail(
            "Marketplace and plugin directories differ: "
            f"plugins={sorted(plugin_names)}, codex={sorted(codex_names)}, "
            f"claude={sorted(claude_names)}"
        )

    for plugin_dir in plugin_dirs:
        validate_plugin(plugin_dir)

    for path in ROOT.rglob("*"):
        if path.is_file() and path.suffix in {".md", ".json", ".yaml", ".yml", ".py", ".sh"}:
            text = path.read_text(errors="replace")
            if "[" + "TODO:" in text or "FIX" + "ME" in text:
                fail(f"Unresolved placeholder in {path.relative_to(ROOT)}")

    print(f"Validation passed for {len(plugin_dirs)} plugin(s): {', '.join(sorted(plugin_names))}")


if __name__ == "__main__":
    main()
