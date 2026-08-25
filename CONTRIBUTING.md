# Contributing

Each tool in Special Skills is a standalone plugin module under `plugins/<module>`.

When adding or changing a module:

1. Keep the module directory and both plugin manifest names identical.
2. Register the module in `.agents/plugins/marketplace.json` and `.claude-plugin/marketplace.json`.
3. Give every skill a matching directory/frontmatter name and an MIT license declaration.
4. Keep operational analysis read-only unless a skill explicitly defines a separately authorized mutation phase.
5. Resolve scripts and references relative to the installed plugin or skill, never to the caller's current working directory.
6. Add controlled fixtures for behavior that could produce destructive or expensive recommendations.
7. Run `python3 scripts/validate.py` before opening a pull request.

Do not commit credentials, collected provider evidence, customer identifiers, connection strings, or reports containing sensitive infrastructure metadata.
