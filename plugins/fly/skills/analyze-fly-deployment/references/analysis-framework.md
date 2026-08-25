# Fly Deployment Analysis Framework

## Contents

- Evidence planes and precedence
- Reconciliation states
- Audit domains
- Finding classes
- Severity, confidence, and effort
- Required evidence by claim type
- Common false conclusions

## Evidence planes and precedence

Collect applicable evidence from independent planes:

1. **Declared state:** `fly.toml`, Dockerfiles, image catalogs, IaC, CI/CD, rollout docs, scripts, and version-controlled policy.
2. **Live provider state:** `flyctl`, Machines API, dashboard, app/Machine/release/volume/IP/certificate/managed-service state.
3. **Application control plane:** database registrations, environment/workspace records, deployment operations, leases, release channels, expected image/config fingerprints.
4. **Billing and utilization:** invoice, Cost Explorer, provider pricing, internal cost ledger, Machine runtime, stopped rootfs, volume/snapshot GB-hours, egress, IPs, and managed services.
5. **Observability:** health checks, logs, metrics, incidents, alerts, synthetic probes, application-level verification, and backup/restore evidence.
6. **Authoritative platform reference:** installed CLI help and current first-party Fly.io documentation.

Use this precedence within the same question:

- current live provider state over cached registrations;
- current repository implementation and tests over stale issues or design notes;
- invoice/Cost Explorer over internal estimated spend;
- exact immutable digest over mutable image tag;
- service-level probe and data validation over process startup;
- successful restore evidence over backup-job success;
- current installed CLI help over remembered flags;
- current primary documentation over old forum guidance.

Do not discard lower-precedence contradictions. Record them as drift or uncertainty.

## Reconciliation states

- **Confirmed:** two or more independent applicable sources agree, with live provider evidence for live claims.
- **Drift:** declaration, provider, control-plane, or cost state disagree.
- **Orphan candidate:** provider or billed resource lacks a visible declaration or owner in the evidence collected so far; it is not yet a deletion target.
- **Orphan:** targeted searches confirm that a provider or billed resource has no current declaration, owner, dependency, controller purpose, or approved retention purpose.
- **Phantom:** a declaration/control-plane record claims a resource that provider evidence cannot confirm.
- **Unverified:** a decisive source is unavailable, unauthorized, stale, or incomplete.
- **Contradictory:** sources conflict and supersession cannot be established.
- **Expected divergence:** difference is intentional, documented, owned, and tested.

## Audit domains

### 1. Topology and ownership

Check organization/app/environment/project boundaries; Machine roles and process groups; public, private, and administrative network paths; data-service relationships; owner, criticality, creation path, desired-state controller, and retirement policy. Flag unowned resources, ambiguous controllers, accidental cross-environment sharing, and obsolete app topology.

### 2. Releases, images, and rollback

Check exact image digest per role and Machine; source revision and build provenance; mutable tags versus immutable references; failed or partial rollout; health-gated strategy and schema compatibility; known-good rollback retention; and the difference between image, config, secret, and data rollback.

Do not claim registry cleanup support that `fly image` does not provide. `fly machine destroy --image` destroys Machines using a hash; it does not delete a registry image.

### 3. Machine lifecycle and cleanup

Check Machine state, age, release, health, restart loop, traffic role, Fly Launch management, pool purpose, auto-destroy jobs, volume attachments, cordon/drain behavior, and controllers that recreate deleted resources.

Treat stop, suspend, kill, and destroy as distinct. Stopped/suspended rootfs may still cost money; attached or unattached volumes continue billing.

### 4. Compute, scaling, and cost

Check CPU kind/count, memory, process-group sizing, CPU throttling, memory peaks, OOM, latency, concurrency, `[[vm]]` precedence, autostop/autostart pairing, primary-region minimums, private routing, metrics autoscaling, always-on justification, all independent resource charges, cross-region transfer, and reconciliation to provider billing.

Never present an internal estimate as an invoice. Do not recommend downsizing from averages alone; consider peaks and failure margin.

### 5. Storage, databases, backups, and recovery

Check rootfs writes, volume attachment/region/size/utilization/auto-extension/zone/replication, unattached volumes, snapshots, application-consistent independent backups, RPO/RTO, encryption, retention, deletion protection, monitoring, and actual restoration evidence. Distinguish Managed Postgres recovery from unsupported unmanaged Fly Postgres operations. Check Tigris snapshot-at-creation requirements and managed services that outlive app deletion.

High availability is not backup. A snapshot is not a proven backup until restoration and application validation succeed.

### 6. Networking, DNS, TLS, and egress

Check services/internal ports/listening addresses, health-check routing, shared versus dedicated IPv4, static egress and allowlists, IPv6/private network/Flycast, DNS, certificates, stale hostnames, cross-region paths, public exposure, and egress cost.

Verify DNS/TLS with a real service request. Allocation or certificate status alone is not end-to-end proof.

### 7. Reliability and deployments

Check redundancy by role/region, single-host or volume exposure, readiness checks, deployment-strategy constraints, `max_unavailable`, release-command volume behavior, graceful shutdown, restart policy, leases, concurrent deploy control, incident/rollback runbooks, and recovery-test evidence.

A running Machine, open port, or successful CLI command is not sufficient service proof.

### 8. Security and access

Check scoped token type, name, owner, expiry, rotation, and revocation; personal auth tokens in CI; secrets names/digests and staged versus deployed state without exposing values; deploy access as effective secret-reading capability; registry/build secrets; supply-chain provenance; image scanning/signing where required; organization roles; and staging/production separation.

### 9. Observability and incident operations

Check logs, metrics, checks, synthetics, alerts, incidents, retention/export, per-role dashboards, alert ownership, request correlation, backup age, cost-review ownership, and distinction between last-known and freshly collected state.

### 10. Automation and change control

Check pinned CI setup, per-app concurrency, explicit targets, least-privilege credentials, declarative state versus imperative drift, review-app cleanup, exact-ID destructive manifests, backup/approval gates, controller idempotency, leases, retry/replacing behavior, staged-config activation, and post-change verification.

## Finding classes

Use exactly one primary class per conclusion:

- **Finding:** verified state needed to understand the deployment. It may be healthy, neutral, or contextual.
- **Issue:** verified current defect, risk, gap, drift, orphan, failed control, or unowned exposure.
- **Fix:** direct remediation for an Issue. Link it to the Issue ID.
- **Opportunity:** optional optimization or simplification whose absence is not a defect.
- **Enhancement:** net-new product/platform capability, automation, or control beyond remediation.

Do not relabel an unsupported suspicion as an Issue. Use an Unknown or a targeted verification step.

## Severity, confidence, and effort

### Issue severity

- **Critical:** active or imminent data loss, security compromise, broad production outage, unrecoverable deployment, or uncontrolled destructive action.
- **High:** material reliability/security/data-recovery failure, large verified waste, or likely production impact requiring near-term action.
- **Medium:** bounded risk, drift, operational weakness, or recurring inefficiency with a practical workaround.
- **Low:** minor hygiene, maintainability, documentation, or small optimization issue.

Severity describes impact and urgency, not confidence.

### Confidence

- **High:** direct current evidence from the owning source, usually corroborated.
- **Medium:** credible partial evidence or a well-supported inference with one meaningful gap.
- **Low:** indirect, stale, ambiguous, or single-plane evidence; normally report as an Unknown, not an Issue.

### Effort

- **S:** hours, one owner, reversible, no migration.
- **M:** days, coordination or rollout required.
- **L:** multi-week, architectural, migration, or cross-team work.

## Required evidence by claim type

| Claim | Minimum evidence |
|---|---|
| Live resource exists/does not exist | Fresh provider query with valid authority |
| Resource is an orphan candidate | Live existence plus no visible owner/declaration in current evidence |
| Resource is orphaned | Live existence plus no owner/declaration/dependency/controller/retention purpose after targeted search |
| Resource is wasteful | Provisioned/billed state plus utilization or absence of purpose |
| Image is deployed | Exact Machine/release image reference, preferably digest |
| Release is healthy | Checks plus service/application behavior and relevant metrics/logs |
| Backup is healthy | Recent successful job, independent stored artifact, and restoration evidence |
| Cost is actual | Invoice or provider Cost Explorer; otherwise label estimate |
| Cleanup is safe | Exact target, dependency/attachment check, owner approval, backup/rollback evidence, recreation path disabled |
| Fix is complete | Post-change provider state plus behavior that failed before |

## Common false conclusions

- A 401 means there are no resources. It means authority failed.
- A database registration proves a live Machine exists. It proves only the record exists.
- A running Machine means the application is healthy. It proves only runtime state.
- A successful deploy command means the release is complete. Verify exact revision, image, checks, and behavior.
- A snapshot means data is safely backed up. Verify independent restore and application consistency.
- Stopping a Machine stops all cost. Rootfs, volumes, snapshots, IPs, and managed services may remain billable.
- Deleting an app deletes every attached service. Inventory MPG, Redis, Tigris, and extensions separately.
- Old registry tags can be listed/pruned with `fly image`. They cannot through the current general CLI surface.
- Manual resizing persists. `[[vm]]` in `fly.toml` may reset it on deploy.
- Autoscaling always creates Machines. Proxy autostop/autostart only changes existing Machine state.
- A proposed control earns audit credit. Only implemented and verified behavior does.
