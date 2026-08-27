# Special Skills

Focused agent tools for infrastructure and engineering operations. Each tool is an independently installable module under `plugins/`, with manifests for Codex and Claude Code.

## Fly module: Fly Swatter

Fly Swatter performs deep, evidence-backed analysis of Fly.io deployments. It reconciles repository configuration, live provider state, application control-plane records, observability, backups, storage, and billing evidence.

It reports five distinct kinds of conclusions:

- **Findings:** verified material current state.
- **Issues:** verified defects, risks, gaps, or drift.
- **Fixes:** specific remediations tied to issues.
- **Opportunities:** optional efficiency or cost improvements.
- **Enhancements:** useful new operational capabilities.

Its main coverage includes Machines, releases and images, persistent volumes, snapshots and restore readiness, managed services, networking, health checks, deployment safety, access controls, observability, cleanup candidates, capacity, and cost reconciliation.

Fly Swatter is read-only by default. It does not deploy, restart, resize, restore, destroy, or clean up infrastructure unless the user separately authorizes an exact change. An unattached or unexplained resource remains an **orphan candidate** until ownership, dependencies, controller behavior, and retention needs have been checked.

## Install in Codex

Add this repository as a marketplace and install the Fly module:

```bash
codex plugin marketplace add greg-asher/special-skills --ref main
codex plugin add fly@special-skills
codex plugin add nist-ai-risk@special-skills
```

Run Fly Swatter:

```text
$analyze-fly-deployment Deeply audit this Fly.io deployment, focusing on cleanup, backups, storage, reliability, and cost.
$manage-ai-risk Help me examine this project's AI risks and maintain its .nist record.
```

## Install in Claude Code

```text
/plugin marketplace add greg-asher/special-skills
/plugin install fly@special-skills
/plugin install nist-ai-risk@special-skills
```

Run Fly Swatter:

```text
/fly:analyze-fly-deployment Deeply audit this Fly.io deployment, focusing on cleanup, backups, storage, reliability, and cost.
/nist-ai-risk:manage-ai-risk Help me examine this project's AI risks and maintain its .nist record.
```

## Live Fly access

The plugin does not include credentials. When a user authorizes live inspection, it uses the locally installed `fly` CLI and its current authenticated identity. The bundled evidence collector accepts explicit app and organization targets, supports a production-friendly dry run, and records commands, output, errors, and exit status separately.

Authentication failure is reported as an evidence gap—not as proof that no Fly resources exist. Collected configuration may contain internal metadata and should be handled as sensitive evidence.

## NIST AI Risk module: Manage AI Risk

Manage AI Risk is a developer-invoked helper for examining AI-enabled project work and maintaining one living `.nist` Markdown record at the project root. It uses NIST AI RMF Govern, Map, Measure, and Manage as an internal reasoning lens, with the NIST Generative AI Profile applied only when relevant.

The skill inspects only project evidence relevant to the developer's request, supports several AI capabilities in one project, and records concrete risk scenarios without turning the framework into a questionnaire. It has zero gatekeeping capability: no compliance verdicts, release approvals, aggregate scores, blocking behavior, or CI enforcement.

## Repository layout

```text
special-skills/
├── .agents/plugins/marketplace.json
├── .claude-plugin/marketplace.json
├── plugins/
│   ├── fly/
│   │   ├── .codex-plugin/plugin.json
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/analyze-fly-deployment/
│   └── nist-ai-risk/
│       ├── .codex-plugin/plugin.json
│       ├── .claude-plugin/plugin.json
│       └── skills/manage-ai-risk/
└── scripts/validate.py
```

Future tools should be added as sibling modules under `plugins/` and registered in both marketplace catalogs.

## Validate

```bash
python3 scripts/validate.py
```

## License

MIT. Fly Swatter and NIST AI Risk are independent community tools and are not affiliated with or endorsed by Fly.io or NIST.
