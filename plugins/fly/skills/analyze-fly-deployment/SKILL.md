---
name: analyze-fly-deployment
description: Deeply audit Fly.io deployments and Fly Launch or Machines-based infrastructure by reconciling repository configuration, live flyctl or Machines API state, application control-plane records, observability, backups, storage, and billing evidence. Use for Fly architecture reviews, deployment health audits, incident analysis, machine or image cleanup, volume and backup reviews, cost/resource optimization, security/access reviews, release and rollback readiness, or requests to identify issues, findings, fixes, enhancements, and improvement opportunities. Analysis is read-only unless the user separately authorizes changes.
license: MIT
---

# Analyze Fly Deployment

Produce an evidence-backed current-state audit and prioritized improvement plan. Distinguish verified defects from observations and optional architecture. Never substitute stale configuration or database registrations for live provider truth.

## Guardrails

- Treat analysis as read-only. Do not deploy, restart, stop, suspend, destroy, scale, update, release, allocate, revoke, rotate, restore, or mutate resources unless the user explicitly asks for that action.
- Start from the exact app, organization, repository, `fly.toml`, incident, Machine ID, URL, or evidence artifact the user names. Do not widen cleanup scope silently.
- Use explicit `--app`, `--org`, and `--config` selectors. Never rely on ambient app inference for destructive recommendations.
- Do not expose token values, secret values, connection strings, or raw credentials in evidence or reports.
- Verify current CLI flags, pricing, product status, and provider behavior against installed `fly --help` and current first-party documentation when they affect a conclusion.
- If live authentication fails, state that provider truth is unverified. Continue with other evidence planes, but do not claim a live inventory.

## Load bundled resources

Read [references/analysis-framework.md](references/analysis-framework.md) for evidence planes, source precedence, audit domains, severity, confidence, and finding classification.

Read [references/fly-operations-handbook.md](references/fly-operations-handbook.md) when the task concerns command capabilities, lifecycle semantics, cleanup, cost, storage, backups, networking, or operating practice. Search it by relevant terms rather than loading unrelated sections when context is constrained.

Use [assets/audit-report-template.md](assets/audit-report-template.md) as the output structure for a full audit. Shorter questions may use only the applicable sections.

Use `scripts/collect-fly-evidence.sh`, resolved relative to this skill directory, for an explicit app or organization when live CLI access is in scope. In Claude Code its installed path is `${CLAUDE_PLUGIN_ROOT}/skills/analyze-fly-deployment/scripts/collect-fly-evidence.sh`; in other hosts resolve the absolute path from this `SKILL.md`. Run it with `--dry-run` first for production or broad organization inventories. The script is read-only and stores stdout, stderr, exit status, and exact commands separately. Treat the evidence directory as sensitive because provider configuration can contain internal metadata; sanitize the user-facing report.

## Workflow

### 1. Bound the audit

Record:

- organization, apps, environments, regions, process groups, and user-facing services in scope;
- repository/config paths and branch or revision;
- requested focus: health, architecture, cleanup, cost, storage, backup, security, deployment, incident, or complete audit;
- production versus non-production classification;
- whether live Fly access is available and authorized;
- desired output location and decision the report should support.

Make reasonable read-only assumptions when scope can be discovered. Ask only when a missing choice would materially change the target or authorize a mutation.

### 2. Establish authority and freshness

Check the installed CLI version and identity before querying live state:

```bash
fly version
fly auth whoami
```

Record collection timestamps and source revision. An HTTP 401/403, filtered token output, local config-permission failure, or unavailable organization is an evidence gap—not proof that resources do not exist.

### 3. Discover declared topology

Inspect the repository before interpreting provider state. Search for:

- every `fly.toml`, Dockerfile, image catalog, rollout document, and deployment script;
- CI workflows invoking `fly`, Machines API, registry pushes, or cleanup;
- app names, organization names, regions, process groups, Machine sizes, mounts, services, checks, deploy strategy, restart/autostop policy, secrets names, IPs, and certificates;
- Terraform, Pulumi, custom Machines API clients, controllers, review-app automation, and scheduled jobs;
- application database tables or registries representing environments, Machines, releases, volumes, leases, operations, backups, or cost;
- metering and billing calculations, prices, fallbacks, gaps, and invoice reconciliation.

Build a topology model that distinguishes app, Machine role, process group, image, region, network path, persistent store, owner, creator, and lifecycle controller.

### 4. Collect live provider evidence

Prefer the bundled collector:

```bash
<skill-root>/scripts/collect-fly-evidence.sh \
  --org my-org \
  --app my-app \
  --output /absolute/path/to/evidence \
  --dry-run
```

After reviewing the command plan, omit `--dry-run` to collect. For a focused incident, query only the named app or Machine rather than collecting the entire organization.

At minimum reconcile:

- app status and Fly Launch versus unmanaged Machines;
- Machine IDs, roles, states, sizes, images/digests, regions, health, restart/autostop, and mounts;
- releases, exact images, deployment age/status, and rollback targets;
- volumes, attachment, size, region, snapshot schedule/retention, and deleted/unattached state;
- public/shared/dedicated/egress IPs, certificates, services, and checks;
- Managed Postgres, Redis, Tigris, and extensions that can outlive app deletion;
- current billing or Cost Explorer evidence when available.

### 5. Reconcile evidence planes

Create a compact matrix for each resource or claim:

| Claim/resource | Declared | Live provider | Control plane/DB | Billing/metrics | Status |
|---|---|---|---|---|---|

Classify reconciliation as:

- **Confirmed:** independent applicable planes agree.
- **Drift:** desired and live state disagree.
- **Orphan candidate:** live/billed resource lacks a visible owner or declaration in the evidence collected so far.
- **Orphan:** targeted searches confirm the live/billed resource has no current owner, declaration, dependency, controller purpose, or approved retention purpose.
- **Phantom:** control-plane/declaration record has no verified provider resource.
- **Unverified:** required authority or source is unavailable.
- **Contradictory:** sources disagree and neither clearly supersedes the other.

Prefer current implementation/tests over stale issue history and current provider state over cached registrations. Prefer invoices/Cost Explorer over internal estimates for actual spend; retain internal estimates as estimates.

### 6. Analyze every applicable domain

Use the domain checklist in `references/analysis-framework.md`. A complete audit covers:

1. topology and ownership;
2. release, image, registry, and rollback integrity;
3. Machine lifecycle, capacity, placement, and cleanup;
4. compute sizing, autostop, concurrency, and cost;
5. volumes, object storage, databases, backups, and recovery;
6. networking, DNS, TLS, IPs, and egress;
7. availability, health checks, deployments, and failure recovery;
8. tokens, secrets, permissions, and supply chain;
9. logs, metrics, alerts, auditability, and incident operations;
10. automation, desired-state ownership, change control, and resource re-creation paths.

Do not award credit for a proposal that is not implemented or for a running Machine without service-level proof.

### 7. Classify and prioritize conclusions

Every conclusion must use exactly one primary class:

- **Finding:** verified material current state, neutral or contextual.
- **Issue:** verified defect, risk, gap, drift, orphan, or control failure.
- **Fix:** specific action that directly resolves a verified issue.
- **Opportunity:** optional efficiency, simplification, or cost improvement.
- **Enhancement:** net-new capability beyond correcting current behavior.

Do not mix optional architecture into the issue count. Pair each Issue with a Fix when one is supportable. Assign severity only to Issues and confidence to all conclusions. Include exact evidence, affected resources, impact, recommendation, validation method, effort, dependencies, and mutation risk.

### 8. Produce the audit

Lead with the direct operational answer:

- what is healthy, unhealthy, wasteful, risky, or unverified;
- the few actions that matter most;
- whether cleanup, backup, rollback, and cost controls are trustworthy;
- what cannot be concluded from available authority.

Use the bundled template. Keep evidence near each claim and link to current primary documentation for changing platform behavior. Include a prioritized remediation sequence that separates:

1. immediate containment or data-safety work;
2. quick reversible fixes;
3. planned remediation;
4. optional optimizations;
5. independent enhancements.

When saving in a repository, follow its documentation convention. Otherwise save a dated Markdown report in the user's requested destination or `outputs/`.

### 9. Verify the report

Before delivery:

- recheck app/org/resource identifiers and timestamps;
- confirm each Issue has direct evidence and is not merely a possibility;
- confirm cleanup candidates are not labeled Orphans until targeted owner, dependency, controller, and retention searches are complete;
- confirm each Fix addresses the first component that makes behavior wrong;
- confirm cost numbers are labeled invoice, provider estimate, or internal estimate;
- confirm backup claims include restoration evidence or are labeled untested;
- confirm no secret values or sensitive connection strings are present;
- confirm recommendations do not mutate resources without authorization;
- list contradictions, inaccessible evidence, and remaining unknowns.

## Mutation boundary

If the user later asks to apply fixes, treat that as a new change phase. Re-read the exact approved findings, refresh live state, show the exact resources and commands, preserve backups/rollback paths, and request any authorization required for destructive or production operations. Analysis completion never implies permission to deploy or clean up.
