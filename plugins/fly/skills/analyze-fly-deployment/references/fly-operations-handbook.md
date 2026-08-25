# The Fly.io CLI: Team Operations Handbook

**Audience:** Engineers and operators who deploy, maintain, troubleshoot, or clean up Fly.io resources

**Current through:** August 24, 2026

**CLI baseline inspected:** `flyctl v0.4.87` (built August 20, 2026)
**Scope:** The `fly`/`flyctl` command surface, with additional depth on Machines, images, compute optimization, volumes, object storage, backups, recovery, and cost hygiene.

> `fly` and `flyctl` are the same CLI. This handbook uses `fly`, which is the spelling used in current Fly.io documentation.

## Executive answer

`flyctl` is the primary operational interface to Fly.io. It covers app creation and deployment; individual Machine lifecycle; horizontal and vertical scaling; networking; certificates; secrets; observability; volumes; Managed Postgres; unmanaged Postgres; Redis; Tigris object storage; organization access; tokens; private networking; troubleshooting; and automation-friendly JSON output.

The safe way to operate it is to treat Fly.io as a collection of independently billable resources—not as a single app object. A stopped Machine releases CPU and RAM charges but still incurs root filesystem storage charges. A volume is billed while attached, unattached, or attached to a stopped Machine. Snapshots are also billable. Dedicated and static egress IPs can remain billable. Managed Postgres, Upstash Redis, Tigris, and extensions live outside the application lifecycle, so deleting an app is not a complete cleanup. See Fly.io's current [billing model](https://fly.io/docs/about/billing/), [resource pricing](https://fly.io/docs/about/pricing/), and [cost-management guidance](https://fly.io/docs/about/cost-management/).

The most important team practices are:

1. Inventory first; mutate second. Use explicit organization and app selectors and machine-readable output.
2. Stop for temporary scale-down; destroy for permanent removal. Do not confuse either with image-registry cleanup.
3. Keep persistent data off the ephemeral root filesystem.
4. Treat Fly Volume snapshots as a short recovery layer, not the primary backup plan.
5. Maintain an independent, application-consistent backup and prove restoration on a schedule.
6. Keep desired state in `fly.toml` and version control. Manual scaling can be overwritten by the next deploy.
7. Use least-privilege, expiring tokens for automation.
8. Review all provisioned resource families and the billing dashboard regularly; Fly.io does not currently provide billing alerts.

## 1. Mental model: what the CLI is managing

### App

A Fly App is a namespace and configuration boundary. It can contain Machines, releases, secrets, services, certificates, IP allocations, and volumes. An app is not itself a VM and is not necessarily the lifecycle owner of managed services attached to it.

### Machine

A Fly Machine is a Firecracker microVM created from an OCI container image. Its configuration includes the image, CPU/RAM, process, services, checks, restart policy, mounts, metadata, and region. Machines can be created, started, stopped, suspended, updated, cordoned, cloned, killed, or destroyed. The current Machines API exposes the same core lifecycle, lease, and cordon operations described in the [Machines resource reference](https://fly.io/docs/machines/api/machines-resource/).

### Image and root filesystem

Fly unpacks a container image into a Machine root filesystem. The root filesystem is ephemeral by default; a restart, deploy, or Machine update normally rebuilds it. Persistent application data belongs on a volume, in a database, or in object storage—not in rootfs. Fly documents the `persist_rootfs` exceptions (`never`, `restart`, and `always`) in the [`fly.toml` VM reference](https://fly.io/docs/reference/configuration/#the-vm-section), but relying on rootfs persistence makes replacement and recovery harder and should be exceptional.

### Volume

A Fly Volume is local NVMe-backed persistent block storage tied to one physical host and attached to one Machine. Volumes do not replicate themselves and cannot be shared concurrently by multiple Machines. Fly explicitly recommends at least two volumes for production workloads and requires the application or database to replicate between them. See the [Fly Volumes overview](https://fly.io/docs/volumes/overview/).

### Snapshot

Fly takes daily block-level volume snapshots by default. The default retention is five days and the configurable range is 1–60 days. Snapshots are incremental for billing and can restore into a **new** volume of equal or greater size. Fly explicitly says snapshots should not be the primary backup method. See [volume snapshots](https://fly.io/docs/volumes/snapshots/) and [volume management](https://fly.io/docs/volumes/volume-manage/).

### Managed service

Managed Postgres, Upstash Redis, Tigris object storage, and other extensions may be connected to an app but have independent lifecycle and billing. Deleting an app does not prove those services were deleted. Fly calls this out in its [cost-management guidance](https://fly.io/docs/about/cost-management/).

## 2. Complete capability map

This maps the top-level command surface present in `flyctl v0.4.87`. Use `fly <command> --help` and `fly <command> <subcommand> --help` as the version-matched source of truth.

| Capability | Commands | What the team uses them for |
|---|---|---|
| App bootstrap and lifecycle | `launch`, `apps`, `deploy`, `status`, `releases` | Create apps, generate config, build/deploy releases, inspect state, restart or destroy apps, find rollback images |
| Desired configuration | `config`, `secrets`, `image` | Validate/save/show `fly.toml`, manage encrypted runtime secrets, inspect or update the app image |
| Machine lifecycle | `machine` | Create/run/clone/update/start/stop/suspend/restart/kill/destroy Machines; cordon traffic; simulate placement; manage leases |
| Resource scaling | `scale`, `platform vm-sizes` | Change Machine count, CPU class/size, and memory; inspect regional capacity and sizes |
| Persistent block storage | `volumes` | Create, list, inspect, update, extend, fork, snapshot, restore, and destroy volumes |
| Public and private networking | `ips`, `services`, `certs`, `wireguard`, `dig`, `ping`, `proxy` | Allocate/release ingress and egress IPs, inspect services, manage TLS, connect to the private network, test routing and DNS |
| Remote access and file transfer | `ssh`, `console`, `sftp`, `machine exec` | Open shells, run commands, and move files for diagnostics or maintenance |
| Observability and health | `logs`, `checks`, `synthetics`, `incidents`, `dashboard`, `jobs` | Tail logs, inspect checks, run synthetic monitoring, view incidents, inspect platform jobs and the web UI |
| Databases and data services | `mpg`, `postgres`, `redis`, `storage`, `litefs-cloud`, `consul` | Manage Managed Postgres, legacy unmanaged Postgres, Upstash Redis, Tigris object storage, LiteFS Cloud, and Consul |
| Extensions | `extensions` | Provision integrations such as Arcjet, Kubernetes, Sentry, Tigris, Upstash Vector, and Wafris |
| Identity and organization | `auth`, `tokens`, `orgs` | Sign in/out, identify the current principal, create/revoke scoped tokens, manage organizations |
| Diagnostics and platform discovery | `doctor`, `platform`, `docs`, `version` | Check local connectivity, list regions and VM sizes, open documentation, and inspect/update the CLI |
| Local CLI support | `agent`, `completion`, `settings` | Manage the WireGuard helper, generate shell completion, and control local settings |
| Agent/tool integration | `mcp` | Run the CLI's Model Context Protocol capability where applicable |

The generated [Fly CLI reference](https://fly.io/docs/flyctl/) mirrors the released command tree, while the [integration guide](https://fly.io/docs/flyctl/integrating/) documents JSON output and CI behavior.

## 3. The team's operating rules

### Always select the target explicitly

`fly` may infer an app from the current directory's `fly.toml` or from `FLY_APP`. That is convenient but dangerous during cleanup. For state-changing operations, spell out the target:

```bash
fly machine list --app my-app
fly volumes list --app my-app
fly deploy --app my-app --config ./fly.toml
```

For organization-wide commands, use `--org <org-slug>` when supported. Before a destructive command, run `fly auth whoami`, show the target resource, and have a second operator verify production deletions.

### Prefer desired state over one-off drift

For Fly Launch apps, keep `fly.toml` in version control and make CPU, memory, process groups, mounts, services, checks, deployment strategy, and autostop behavior explicit there. The `[[vm]]` settings take precedence: a manual `fly scale vm` or `fly scale memory` change can be reset by the next deploy. Fly documents the precedence in [Scale Machine CPU and RAM](https://fly.io/docs/launch/scale-machine/).

Use direct `fly machine` commands for intentionally unmanaged Machines, jobs, experiments, or infrastructure controllers. Do not mix managed and unmanaged Machines accidentally; `fly status` warns when it finds Machines outside Fly Launch management.

### Use JSON for automation

Many commands support `--json`/`-j`. JSON output is a contract suitable for `jq`; human-formatted tables are not. Fly's [CLI integration guide](https://fly.io/docs/flyctl/integrating/#json-output-for-scripting) includes examples for status, Machine state, images, and region counts.

### Put safety gates around deletion

Never start a cleanup script with `--yes`, `--force`, or a broad shell loop. A safe cleanup has two phases:

1. Produce and retain an inventory with resource IDs, names, state, region, attachment, owner, age, and proposed action.
2. Apply an approved manifest containing exact resource IDs.

Commands such as `fly machine destroy --force`, `fly volumes destroy --yes`, `fly storage destroy`, `fly mpg destroy`, and `fly apps destroy` are irreversible or may create a difficult recovery. Preserve prompts for human-driven work. In automation, make the manifest and approval the confirmation—not an unreviewed selector.

## 4. Inventory and cleanup runbook

### Step 1: Establish identity, organization, and CLI version

```bash
fly version
fly auth whoami
fly orgs list
```

Update an old CLI before diagnosing strange behavior. Fly's current troubleshooting sequence begins with updating the CLI, running `fly doctor`, validating config, checking logs, and using SSH when necessary. See [Troubleshoot your deployment](https://fly.io/docs/getting-started/troubleshooting/).

### Step 2: Inventory every resource family

Start with apps:

```bash
fly apps list --org my-org
```

For every app:

```bash
fly status --app my-app
fly machine list --app my-app
fly scale show --app my-app
fly volumes list --app my-app
fly ips list --app my-app
fly certs list --app my-app
fly releases --app my-app --image
fly secrets list --app my-app
```

Then inventory services that can outlive the app:

```bash
fly mpg list --org my-org
fly redis list --org my-org
fly storage list --org my-org
```

Also review provisioned extensions in their corresponding provider/extension dashboard and review the organization's current month-to-date bill and Cost Explorer. Fly currently says it does **not** support billing alerts, so this must be an owned operating cadence rather than an assumed platform control. See [Cost Management on Fly.io](https://fly.io/docs/about/cost-management/).

### Step 3: Classify—not yet delete—candidates

| Candidate | Why it matters | Default action |
|---|---|---|
| Started Machine with no traffic/owner | Full CPU/RAM cost | Verify service ownership; right-size or enable autostop |
| Stopped/suspended Machine no longer needed | CPU/RAM is released, but rootfs storage remains billable | Destroy after confirming it is not a capacity pool or image-retention anchor |
| Unattached volume | Still billed; may contain the only remaining data copy | Identify owner and snapshots; restore-test or export before destruction |
| Oversized volume | Provisioned capacity is billed and volumes cannot shrink | Create a smaller replacement, migrate/verify data, cut over, then destroy old volume |
| Excess snapshot retention | Snapshot storage is billable | Match retention to RPO; do not reduce without an independent backup |
| Dedicated IPv4/static egress IP no longer required | Billed independently | Migrate to shared IPv4 where possible; verify DNS/allowlists, then release |
| Managed Postgres/Redis/Tigris with no app | Independent service continues billing | Confirm data owner and retention requirement; back up and explicitly destroy if approved |
| Old certificate hostname | Certificates may be billable above allowance | Verify DNS and traffic, then `fly certs remove` |
| Legacy `fly-builder-*` app | May be an old remote builder rather than production | Verify it is a builder and current build path before considering removal |
| Remote registry image | Fly may prune unused images; no general tag-list/delete API | Do not create a fake cleanup process; manage retention in an external registry if required |
| Local Docker build cache/images | Consumes developer/CI disk, not Fly resources | Audit with `docker system df`; apply age-filtered local pruning |

### Step 4: Sequence cleanup from least to most destructive

1. Correct config drift and disable unintended creation paths.
2. Stop or suspend stateless Machines temporarily and observe.
3. Remove unused dedicated/egress IPs and certificates after validation.
4. Destroy approved stateless Machines.
5. Verify backups and perform a restore test before touching persistent data.
6. Destroy approved unattached volumes and managed services by exact ID/name.
7. Destroy the app only after the external-service inventory is clean.
8. Re-run the complete inventory and check current-month billing.

## 5. Machines: lifecycle and cleanup

### Stop, suspend, kill, or destroy?

| Operation | Intended use | Data/runtime behavior | Cost effect | Risk |
|---|---|---|---|---|
| `fly machine stop <id>` | Temporary scale-down or maintenance | Graceful shutdown; next start is normally a cold, clean boot; volumes persist | Releases CPU/RAM; rootfs and volumes remain billable | Requests may autostart it if services allow |
| `fly machine suspend <id>` | Faster wake-up for compatible, smaller workloads | Saves VM state including memory; resume is attempted but not guaranteed; volume is independent | Similar compute relief to stop; retained storage still bills | Clock skew, stale network connections, snapshot loss; design for cold boot too |
| `fly machine kill <id>` | Unresponsive Machine that cannot stop cleanly | Sends SIGKILL | Does not remove the Machine | Can interrupt writes and corrupt application state |
| `fly machine destroy <id>` | Permanent removal | Deletes Machine; an attached volume becomes unattached and must be handled separately | Ends Machine/rootfs billing; volume billing continues if volume exists | Irreversible Machine deletion |
| `fly apps destroy <app>` | Remove the whole app and its in-app resources | Deletes app, Machines, app volumes, IPs, and related app resources | Does not prove external managed services were deleted | Broad blast radius |

Fly's [Machine suspend reference](https://fly.io/docs/reference/suspend-resume/) says suspend snapshots memory, can resume in hundreds of milliseconds, is not recommended for Machines over 2 GB, can briefly produce clock skew, and is never a guaranteed alternative to cold start. Time-sensitive workloads should prefer stop unless tested under suspend.

### Safe permanent removal

```bash
# 1. Inspect exact target
fly machine status <machine-id> --app my-app

# 2. Inspect all app Machines and volumes
fly machine list --app my-app
fly volumes list --app my-app

# 3. Stop gracefully
fly machine stop <machine-id> --app my-app

# 4. Re-check state and attachment
fly machine status <machine-id> --app my-app
fly volumes list --app my-app

# 5. Destroy only the approved Machine
fly machine destroy <machine-id> --app my-app
```

`fly machine destroy` requires a stopped or suspended Machine unless `--force` is supplied. Avoid `--force` unless a graceful stop is impossible and the data-integrity implications are understood. The command also accepts `--image <image-hash>` to destroy **all Machines using that image hash**. That flag deletes Machines; it does not delete an image. See the [command reference](https://fly.io/docs/flyctl/machine-destroy/).

### Horizontal capacity

`fly scale count` creates or destroys Machines to reach a desired count. Autostop/autostart only starts and stops an existing pool; it does not create or destroy Machines. The maximum available capacity is therefore the number of Machines already created. For bursty workloads, Fly recommends keeping enough Machines for peak load and starting/stopping them as needed because this is faster than creating/destroying them. See [Scale the Number of Machines](https://fly.io/docs/launch/scale-count/) and [Autostop/autostart Machines](https://fly.io/docs/launch/autostop-autostart/).

Recommended defaults for an HTTP service that can tolerate cold starts:

```toml
[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 1
```

Important behavior:

- `min_machines_running` applies only in the primary region.
- Pair autostop and autostart unless the application deliberately shuts itself down.
- Private apps need a Fly Proxy service, typically Flycast, for proxy-driven autostop/autostart.
- Concurrency `soft_limit` influences the proxy's decision to start or stop Machines.
- A stopped Machine can wake due to incoming traffic, including bot traffic.
- Metrics-based autoscaling can create and destroy Machines; proxy autostop cannot.

### Vertical sizing

Use `fly scale show`, platform metrics, latency, CPU throttling, and memory/OOM evidence before resizing. Shared CPUs have a baseline quota and burst balance; performance CPUs receive a full CPU quota and suit sustained CPU work. See [CPU Performance](https://fly.io/docs/machines/cpu-performance/) and [Machine Sizing](https://fly.io/docs/machines/guides-examples/machine-sizing/).

```bash
fly scale show --app my-app
fly scale vm shared-cpu-2x --app my-app
fly scale memory 1024 --app my-app
```

For predictable deploys, express the final decision in `fly.toml`:

```toml
[[vm]]
  size = "shared-cpu-2x"
  memory = "1gb"
  processes = ["app"]
```

Right-sizing rule: make one change at a time, observe a representative traffic window, retain enough RAM to avoid OOM/restart loops, and compare both cost and service-level outcomes. Do not downsize a database VM as if it were stateless compute; database cache and configuration may depend on the old size.

## 6. Images: what cleanup means on Fly.io

### `fly image` does not manage registry garbage collection

The current command has two subcommands:

- `fly image show` — show the image used by the app.
- `fly image update` — update the app to a target/latest image with a rolling restart.

It has no `list-tags`, `delete`, `prune`, or garbage-collection command. Fly's registry documentation says there is no API or GraphQL query to list all registry tags; releases expose only images used in past deploys. Use:

```bash
fly releases --app my-app --image
fly image show --app my-app
docker manifest inspect registry.fly.io/my-app:tag
```

See [Managing Docker Images with Fly.io's Private Registry](https://fly.io/docs/blueprints/using-the-fly-docker-registry/).

### Retention and rollback implications

Fly does not promise to keep an unused app image forever. An image associated with a Machine is retained even if that Machine is stopped, but an old unassociated image may eventually be pruned. Fly's [base-image blueprint](https://fly.io/docs/blueprints/using-base-images-for-faster-deployments/) describes Machine association as the retention anchor; its [rollback guide](https://fly.io/docs/blueprints/rollback-guide/) recommends an external registry for durable long-term rollback targets.

Team policy:

- Tag release images with an immutable version or Git commit, not only `latest`.
- Record the image digest/reference in the deployment record.
- Keep the last-known-good image in an owned registry with an explicit retention policy if rollback beyond Fly's unspecified retention window matters.
- Do not keep purposeless stopped Machines merely to retain every image; stopped rootfs is billable. Retain only deliberate rollback/base-image anchors and review them.
- Remember that an image rollback does not roll back secrets, `fly.toml`, or database schema/data.

Example rollback:

```bash
fly releases --app my-app --image
fly deploy --app my-app \
  --image registry.fly.io/my-app:v1.2.3 \
  --strategy rolling
fly status --app my-app
fly checks list --app my-app
fly logs --app my-app
```

### Optimize the image instead of chasing remote deletion

Smaller images reduce build/pull/deploy time and reduce the rootfs basis billed for stopped Machines. Fly's integration guide notes an 8 GB uncompressed-image limit on standard Machines and recommends Docker layer ordering that copies dependency manifests and installs dependencies before frequently changing source code. Use multi-stage builds, a minimal runtime base, a strict `.dockerignore`, pinned dependencies, and no build caches/toolchains in the final stage. See [Integrating flyctl](https://fly.io/docs/flyctl/integrating/#remote-builds).

### Local Docker cleanup is separate

If developers or CI use `fly deploy --local-only`, local Docker images and build cache consume local disk. Inspect before pruning:

```bash
docker system df --verbose
docker builder prune --filter 'until=168h'
docker image prune
```

Avoid `docker system prune -a --volumes` as a routine shortcut: Docker documents that it removes all unused images and, with `--volumes`, unused anonymous volumes. Use targeted and age-filtered pruning after review. See Docker's official [`system df`](https://docs.docker.com/reference/cli/docker/system/df/), [`builder prune`](https://docs.docker.com/reference/cli/docker/builder/prune/), and [`system prune`](https://docs.docker.com/reference/cli/docker/system/prune/) references.

## 7. Volumes and storage

### Choose the right storage primitive

| Need | Use | Do not assume |
|---|---|---|
| Temporary files, caches, unpacked application code | Ephemeral rootfs | That data survives restart, deploy, update, stop/start, or replacement |
| Low-latency local filesystem state for one Machine | Fly Volume | Built-in replication, shared mounting, shrinking, or primary-backup guarantees |
| Relational production data | Managed Postgres where suitable | That app deletion deletes the cluster |
| Globally distributed S3-compatible object storage | Tigris | That `flyctl` manages objects, lifecycle rules, snapshots, or forks |
| Cache/queue via managed Redis | Upstash Redis integration | That it follows app lifecycle |

### Volume operating facts

- Maximum volume size is 500 GB.
- A volume can be extended but cannot be shrunk.
- Volume performance limits depend on Machine size.
- Volumes and Machines must be in the same region.
- A destroyed Machine can leave its volume unattached.
- Unattached volumes are billed and may be adopted by a later Machine that requires a matching volume.
- Build and release-command Machines do not have access to application volumes.
- Daily snapshots default to enabled with five-day retention.

These constraints are documented in the [volume overview](https://fly.io/docs/volumes/overview/) and [management guide](https://fly.io/docs/volumes/volume-manage/).

### Inspect and manage

```bash
fly volumes list --app my-app
fly volumes show <volume-id> --app my-app
fly volumes snapshots list <volume-id>
```

Change snapshot policy:

```bash
fly volumes update <volume-id> \
  --app my-app \
  --scheduled-snapshots=true \
  --snapshot-retention 14
```

Prefer desired state for Fly Launch apps:

```toml
[[mounts]]
  source = "app_data"
  destination = "/data"
  snapshot_retention = 14
  scheduled_snapshots = true
  auto_extend_size_threshold = 80
  auto_extend_size_increment = "2GB"
  auto_extend_size_limit = "50GB"
```

Auto-extension protects availability but is not a capacity plan: it only grows, can increase cost, and cannot later shrink. Set a hard limit, alert on usage independently, and investigate the growth source.

### Fork, snapshot, and restore

Create an on-demand snapshot before a risky data operation:

```bash
fly volumes snapshots create <volume-id>
fly volumes snapshots list <volume-id>
```

Restore into a new volume; never overwrite the source during the first recovery attempt:

```bash
fly volumes create app_data_restored \
  --app my-app \
  --region iad \
  --size 20 \
  --snapshot-id <snapshot-id>
```

The restored volume must be at least as large as the source. Attach it to a new or cloned Machine, verify the filesystem/application, and cut over explicitly.

A fork creates an independent copy, by default on a different physical host in the same region:

```bash
fly volumes fork <volume-id> --region iad
```

Forks are useful for recovery rehearsal, migrations, or isolated tests. They do not continue syncing and they incur their own volume charges.

### Destroying a volume safely

```bash
# Inspect attachment and all snapshots
fly volumes show <volume-id> --app my-app
fly volumes snapshots list <volume-id>

# Verify an independent backup and restore result before this step
fly volumes destroy <volume-id> --app my-app
```

An attached volume cannot be destroyed. Stop and destroy the attached Machine first, or redeploy without the mount, then verify that the correct volume became unattached. Fly warns that volume destruction permanently deletes its data. A recently deleted volume may be recoverable from retained snapshots if the volume ID is known; `fly volumes list --all` exposes a deleted volume ID for only about 24 hours. Do not make that narrow recovery window the plan.

### Tigris object storage

`fly storage` provisions and manages bucket lifecycle:

```bash
fly storage create --app my-app
fly storage list --org my-org
fly storage status <bucket-name>
fly storage dashboard <bucket-name>
fly storage destroy <bucket-name>
```

Use the Tigris CLI or an S3-compatible SDK for object management and advanced features. `fly storage create` prints access credentials once and, in app context, sets them as Fly secrets; `flyctl` cannot retrieve the secret later. Tigris snapshots and forks are not exposed through `flyctl`, and snapshots must be enabled when a bucket is created—they cannot be enabled later. Buckets created by `fly storage create` do not enable snapshots. See Fly's [Tigris documentation](https://fly.io/docs/tigris/).

For production buckets, decide before creation whether point-in-time history/forks are required. Keep buckets private by default, use narrow/rotated credentials, and confirm the bucket's retention/versioning/lifecycle controls with the Tigris toolchain rather than assuming `fly storage` configured them.

## 8. Backup and disaster recovery standard

### Backup is a recoverability claim, not a file or snapshot

Replication protects availability from a node failure. Snapshots protect a short history of block state. Neither proves that the application can recover from deletion, corruption, a bad migration, compromised credentials, or loss of the Fly account/organization.

Each production data store needs:

- an owner;
- documented RPO (maximum acceptable data loss) and RTO (maximum acceptable recovery time);
- at least one backup copy independent of the production resource and credentials;
- encryption and restricted deletion access;
- retention and expiry rules;
- monitoring for backup completion and age;
- a versioned restoration runbook;
- scheduled restore testing with recorded evidence.

CISA recommends offline/encrypted backups and regular restore testing; NIST frames backups as something that must be conducted, maintained, and tested. See CISA's [StopRansomware Guide](https://www.cisa.gov/stopransomware/ransomware-guide) and NIST's [backup and data-loss guidance](https://csrc.nist.gov/pubs/other/2020/04/24/protecting-data-from-ransomware-and-other-data-los/final).

### Layered baseline

| Layer | Purpose | Example | Limitation |
|---|---|---|---|
| High availability | Keep serving through a Machine/host failure | Multiple Machines and replicated data | Replicates logical corruption/deletion too |
| Short recovery layer | Fast restore from recent infrastructure state | Fly Volume scheduled/on-demand snapshots | Short retention; block-level; same provider/control plane; not primary backup |
| Application-consistent backup | Portable data recovery | `pg_dump`, database-native backup, filesystem/application export | Must be scheduled, monitored, encrypted, and tested |
| Independent copy | Survive account/provider/control-plane loss | Separate object store/account with deletion protection | Additional cost and operational ownership |
| Recovery evidence | Prove RPO/RTO and runbook | Restore into isolated environment and validate | Must be repeated as systems change |

### Managed Postgres

Fly Managed Postgres includes high availability, automatic backups/recovery, replicated storage, and automatic storage growth. The CLI can list/create backups and restore a backup or point in time into a **new**, separately billed cluster, leaving the source unchanged. See [Managed Postgres](https://fly.io/docs/mpg/) and [`fly mpg`](https://fly.io/docs/flyctl/mpg/).

```bash
fly mpg list --org my-org
fly mpg status <cluster-id>
fly mpg backup list <cluster-id>
fly mpg backup create <cluster-id> --type full

# Restore from a backup
fly mpg restore <cluster-id> \
  --backup-id <backup-id> \
  --name my-cluster-recovered

# Or point-in-time restore for a supported v2 cluster/window
fly mpg restore <cluster-id> \
  --pitr-time 2026-08-24T14:30:00Z \
  --name my-cluster-pitr
```

After restore, verify database connectivity, schema, critical row counts/checksums, application reads/writes, roles/extensions, and recovery time before changing application connections. The restored cluster bills separately, so clean it up only after the test evidence is retained. Fly's production checklist explicitly recommends practicing Managed Postgres restoration before an incident. See [Going to production](https://fly.io/docs/apps/going-to-production/).

### Unmanaged Fly Postgres

Fly now labels Fly Postgres as unmanaged and says it cannot provide support or guidance for it. Operators own replication, failover, backup, restore, version compatibility, and scaling. Prefer Managed Postgres for new production workloads unless there is an explicit, staffed reason not to. See [Fly Postgres (Unmanaged)](https://fly.io/docs/postgres/).

For an existing unmanaged cluster:

- keep volume snapshots as a short recovery layer;
- take database-consistent logical or physical backups appropriate to the RPO;
- store independent copies outside the cluster/app;
- include globals/roles where required;
- restore into a new cluster using a compatible Postgres major version;
- validate before detaching/reattaching applications.

PostgreSQL documents that `pg_dump` creates consistent per-database backups during concurrent use and that custom format supports selective/parallel restore; `pg_dumpall --globals-only` is needed for cluster-wide roles and related globals. See the official [PostgreSQL backup documentation](https://www.postgresql.org/docs/current/backup-dump.html).

### Generic volume-backed applications

For SQLite, uploads, indexes, or custom state on a volume:

1. Identify the application's consistency mechanism (transactional online backup, quiesce, checkpoint, or controlled stop).
2. Create the application-consistent export.
3. Store it in independent object storage with encryption and retention.
4. Optionally create an on-demand Fly snapshot as an additional fast rollback point.
5. Restore the export into an isolated app/volume.
6. Run application-level validation, not just `ls` or `df`.
7. Record backup timestamp, restore timestamp, recovered data point, result, and operator.

### Minimum restore-test cadence

Set cadence from business impact, not convenience. A sensible starting point is monthly for ordinary production systems and after any material schema, storage, encryption, or backup-tool change. Critical systems should test more often. Every test must measure the actual RPO/RTO and include credential access, infrastructure recreation, data validation, application startup, and cleanup.

## 9. Cost and resource optimization

### Understand what stopping saves

Started Machines are billed per second for CPU/RAM. Stopped and suspended Machines are billed for rootfs storage. Volumes continue billing in every Machine state and while unattached. Snapshot storage is billed incrementally. Current rates and allowances change, so link operational reviews to the live [pricing page](https://fly.io/docs/about/pricing/) rather than hard-coding a forecast.

### Optimization order

1. Remove genuinely abandoned services and resources.
2. Right-size oversized Machines using measured CPU, memory, latency, and OOM data.
3. Enable autostop/autostart for compatible variable workloads.
4. Reduce the number of always-running Machines without violating availability requirements.
5. Reduce image/rootfs size.
6. Eliminate unattached or oversized volumes after safe migration.
7. Tune snapshot retention to the RPO and independent-backup design.
8. Use shared IPv4 unless a dedicated address is required.
9. Release unused app-scoped or Machine-scoped static egress IPs.
10. Co-locate chatty app/database components where latency and failure design allow; cross-region private transfer is billable.
11. Consider compute reservation blocks only after stable usage proves the commitment will be consumed.

### Network cost hygiene

Shared IPv4 and IPv6 are generally free; dedicated IPv4, certificates beyond allowances, and static egress IPs can be billable. App-scoped static egress IPs persist across Machine destruction and deployments until explicitly released. Inventory with `fly ips list` and release only after DNS and external allowlists are updated. See [Public Network Services](https://fly.io/docs/networking/services/) and [Egress IP addresses](https://fly.io/docs/networking/egress-ips/).

### Avoid hidden re-creation

Deleting a resource is not optimization if configuration, CI, metrics autoscaling, or the next deploy recreates it. Before cleanup, find the creator:

- `fly.toml` process groups and mounts;
- `fly scale count` state;
- metrics autoscaler configuration;
- CI/CD workflows;
- review-app automation;
- Terraform or custom Machines API controllers;
- scheduled scripts;
- human runbooks.

Change the owning source first, then remove the orphan.

## 10. Deployment and release safety

### Preflight

```bash
fly version
fly auth whoami
fly config validate --strict --config ./fly.toml
fly status --app my-app
fly checks list --app my-app
```

### Deployment strategies

- `rolling` (default): update Machines incrementally.
- `immediate`: update everything together; fastest and highest downtime risk.
- `canary`: create and validate one new Machine, then continue rolling.
- `bluegreen`: create parallel Machines, validate all, then move traffic.

Canary and blue-green cannot be used with attached volumes. Blue-green requires health checks. Rolling `max_unavailable` controls how many Machines may be down. See [Deploy an app](https://fly.io/docs/launch/deploy/) and the [`fly.toml` deployment reference](https://fly.io/docs/reference/configuration/#the-deploy-section).

```toml
[deploy]
  strategy = "rolling"
  max_unavailable = 1
  wait_timeout = "10m"
```

Health checks are part of the deployment control plane, not decoration. They gate routing and can halt bad releases. Test them, include meaningful readiness dependencies, and inspect with `fly checks list`. See [Health Checks](https://fly.io/docs/reference/health-checks/).

### Post-deploy verification

```bash
fly status --app my-app
fly checks list --app my-app
fly logs --app my-app
fly releases --app my-app --image
```

Confirm application behavior and metrics as well as CLI success. For schema changes, use expand/contract migrations so old and new application versions can coexist during a rolling or blue-green deploy. An image rollback cannot time-travel the database.

## 11. Authentication, secrets, and automation

### Least-privilege tokens

Do not use `fly auth token` in CI. Fly now recommends scoped tokens and the narrowest access that works:

```bash
# Single-app deploy token
fly tokens create deploy \
  --app my-app \
  --name "ci-my-app" \
  --expiry 720h

# Organization read-only token for inventory/monitoring
fly tokens create readonly \
  --org my-org \
  --name "inventory" \
  --expiry 720h

fly tokens list --scope org
fly tokens revoke <token-id>
```

Store the token in the CI secret store and expose it as `FLY_API_TOKEN` only to the job that needs it. Name tokens, set the shortest practical expiry, rotate, and revoke retired credentials. The default token lifetime can be extremely long if expiry is omitted. See Fly's [Access tokens](https://fly.io/docs/security/tokens/) guidance.

### Secrets

`fly secrets set` encrypts values and makes them available as runtime environment variables. It updates/restarts Machines, which resets the ephemeral filesystem. Use `--stage` when a secret change should be deployed with a coordinated release. `fly secrets list` shows names and digests, not plaintext. Anyone with deploy access can deploy code that reads runtime secrets, so deploy access is sensitive access. See [Secrets and Fly Apps](https://fly.io/docs/apps/secrets/).

### CI concurrency and targeting

- Pin or deliberately update the flyctl setup mechanism; know which version deployed.
- Use a concurrency group per app/environment so two deploys do not race.
- Pass `--app`/`FLY_APP` and `--config` explicitly in monorepos.
- Use `--remote-only` in CI unless local Docker is intentional.
- Use JSON output and non-zero exit status for gates.
- Separate read-only inventory credentials from deployment credentials.
- Do not put destructive cleanup in the normal deploy job.

## 12. Troubleshooting sequence

Use the smallest loop that distinguishes configuration, platform, networking, resource, and application failures:

```bash
fly version
fly doctor
fly config validate --strict --config ./fly.toml
fly status --app my-app
fly checks list --app my-app
fly logs --app my-app
fly machine list --app my-app
fly machine status <machine-id> --app my-app
fly ssh console --app my-app --select
fly incidents
```

Useful principles:

- A started Machine is not necessarily healthy or routable.
- A failed health check can intentionally remove a Machine from routing.
- OOM/restart loops require memory and application evidence, not repeated restarts.
- A volume or disk problem requires backup preservation before repair attempts.
- `suspend` can cause brief clock skew and stale connections; reproduce with `stop` if time-sensitive startup fails.
- Use `fly machine cordon` before planned Machine work when traffic must drain, and `uncordon` only after health verification.
- Use `fly machine leases` or deployment mechanisms that lease Machines when multiple actors might mutate the same Machine.

## 13. Recommended team cadence

### Every deploy

- Validate config.
- Record app, organization, flyctl version, image reference/digest, release, and operator/automation identity.
- Use health-gated deployment strategy.
- Verify status, checks, logs, and application behavior.
- Preserve the known-good rollback image in the required retention system.

### Weekly

- Review failed checks, restart/OOM patterns, Machine counts/states, volume usage, and backup freshness.
- Review unexpected resources created by review apps or autoscaling.
- Review current month-to-date cost.

### Monthly

- Organization-wide app, Machine, volume, IP, certificate, MPG, Redis, Tigris, and extension inventory.
- Owner and expiry review for stopped Machines and unattached volumes.
- Token list, expiry, and revocation review.
- Snapshot retention and independent-backup review.
- Restore test for at least one rotating production system, or more often according to RPO/RTO.
- Compare provisioned capacity and reservation commitments to actual use.

### Quarterly

- Full recovery exercise for each critical recovery pattern.
- Verify that infrastructure/configuration, images, credentials, DNS, data, and monitoring can be reconstructed from the runbook.
- Review this handbook against the installed CLI help, Fly's pricing page, and changed product status.

## 14. Destructive-action checklist

Before destroying a Machine, volume, app, database, bucket, Redis service, IP, or certificate:

- [ ] Correct Fly account and organization confirmed.
- [ ] Exact resource ID/name, app, region, and owner recorded.
- [ ] Creator/automation path disabled or updated.
- [ ] Dependencies and traffic checked.
- [ ] Machine-to-volume attachment checked.
- [ ] Managed services outside the app checked.
- [ ] Required backup completed and independently stored.
- [ ] Restore test completed for persistent/critical data.
- [ ] Required image rollback anchor preserved.
- [ ] DNS and allowlists updated for IP/certificate removal.
- [ ] Approval recorded; a second operator verified production deletion.
- [ ] Destruction uses exact IDs, not a broad selector.
- [ ] Post-cleanup inventory and billing review scheduled.

## 15. Known limitations and unresolved operational choices

- The Fly registry does not expose a general tag-list/delete workflow. Teams needing guaranteed image retention or explicit garbage-collection policy should use an owned external registry.
- Fly Volume snapshots are a useful short recovery layer but are not a sufficient primary backup.
- There is no native billing-alert feature in current Fly documentation. Teams must assign cost review ownership or build external monitoring.
- Tigris bucket snapshots/forks require the Tigris toolchain and must be enabled at bucket creation.
- Suspend snapshots are not guaranteed and have workload-specific caveats.
- Fly Postgres is now explicitly unmanaged; this handbook cannot convert it into a managed service through runbook discipline alone.
- Exact RPO, RTO, retention, cleanup age, regional redundancy, and change-approval requirements are business decisions. The team should fill them in per service tier rather than applying one universal number.
- Pricing, CLI flags, region availability, and managed-service status can drift. Re-verify live documentation and `fly --help` before institutionalizing automation.

## Sources

Primary Fly.io sources:

- [flyctl command reference](https://fly.io/docs/flyctl/)
- [Integrating flyctl](https://fly.io/docs/flyctl/integrating/)
- [App configuration (`fly.toml`)](https://fly.io/docs/reference/configuration/)
- [Machines API resource](https://fly.io/docs/machines/api/machines-resource/)
- [Scale the Number of Machines](https://fly.io/docs/launch/scale-count/)
- [Autostop/autostart Machines](https://fly.io/docs/launch/autostop-autostart/)
- [Machine Suspend and Resume](https://fly.io/docs/reference/suspend-resume/)
- [Machine sizing](https://fly.io/docs/machines/guides-examples/machine-sizing/)
- [CPU performance](https://fly.io/docs/machines/cpu-performance/)
- [Managing Docker Images with Fly.io's Private Registry](https://fly.io/docs/blueprints/using-the-fly-docker-registry/)
- [Rollback Guide](https://fly.io/docs/blueprints/rollback-guide/)
- [Fly Volumes overview](https://fly.io/docs/volumes/overview/)
- [Create and manage volumes](https://fly.io/docs/volumes/volume-manage/)
- [Tigris Global Object Storage](https://fly.io/docs/tigris/)
- [Managed Postgres](https://fly.io/docs/mpg/)
- [Fly Postgres (Unmanaged)](https://fly.io/docs/postgres/)
- [Deploy an app](https://fly.io/docs/launch/deploy/)
- [Health Checks](https://fly.io/docs/reference/health-checks/)
- [Access tokens](https://fly.io/docs/security/tokens/)
- [Secrets and Fly Apps](https://fly.io/docs/apps/secrets/)
- [Fly.io Billing](https://fly.io/docs/about/billing/)
- [Fly.io Resource Pricing](https://fly.io/docs/about/pricing/)
- [Cost Management on Fly.io](https://fly.io/docs/about/cost-management/)
- [Public Network Services](https://fly.io/docs/networking/services/)
- [Egress IP addresses](https://fly.io/docs/networking/egress-ips/)
- [Troubleshoot your deployment](https://fly.io/docs/getting-started/troubleshooting/)
- [Going to production checklist](https://fly.io/docs/apps/going-to-production/)

Additional primary references:

- [Docker: `docker system df`](https://docs.docker.com/reference/cli/docker/system/df/)
- [Docker: `docker builder prune`](https://docs.docker.com/reference/cli/docker/builder/prune/)
- [Docker: `docker system prune`](https://docs.docker.com/reference/cli/docker/system/prune/)
- [PostgreSQL: SQL Dump backup and restore](https://www.postgresql.org/docs/current/backup-dump.html)
- [CISA: StopRansomware Guide](https://www.cisa.gov/stopransomware/ransomware-guide)
- [NIST: Protecting Data from Ransomware and Other Data Loss Events](https://csrc.nist.gov/pubs/other/2020/04/24/protecting-data-from-ransomware-and-other-data-los/final)

## Research note

The command inventory was checked against the locally installed `flyctl v0.4.87` help tree on August 24, 2026. Product behavior, billing, and recommended practices were reconciled primarily against current Fly.io documentation. The highest-drift claims—pricing, snapshot billing, registry limitations, token guidance, Tigris capabilities, and Managed Postgres restore behavior—were verified against current first-party sources. Research stopped when every command family had a mapped purpose, each high-risk lifecycle operation had a safety rule, and each storage/backup recommendation had primary support or was clearly labeled as team policy.
