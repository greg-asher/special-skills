# Fly.io Deployment Deep Analysis: <scope>

**Organization:** <org>

**Apps/environments:** <apps>

**Repository revision:** <revision>

**Evidence collected:** <timestamp and timezone>

**Fly CLI:** <version>

**Authority status:** <verified, partial, or unavailable>
**Mode:** Read-only analysis

## Executive answer

<What is healthy, unhealthy, risky, wasteful, and unverified. Name the top actions.>

## Scope and evidence status

| Evidence plane | Source | Freshness | Authority | Coverage | Limitation |
|---|---|---|---|---|---|
| Declared state | | | | | |
| Live Fly state | | | | | |
| Control plane/DB | | | | | |
| Billing/utilization | | | | | |
| Observability | | | | | |

## Deployment topology

<Describe or diagram apps, Machine roles, process groups, images, regions, network paths, volumes, databases, object storage, and lifecycle owners.>

## Reconciled inventory

| Resource | Role | Region | Declared | Live | Control plane | Cost state | Reconciliation |
|---|---|---|---|---|---|---|---|

## Prioritized conclusions

| ID | Class | Severity | Confidence | Domain | Resource | Conclusion | Recommended action | Effort |
|---|---|---|---|---|---|---|---|---|

## Detailed issues and fixes

### ISSUE-001: <specific defect or risk>

- **Severity:** <Critical, High, Medium, Low>
- **Confidence:** <High, Medium, Low>
- **Affected resources:** <exact IDs/names>
- **Observed:** <direct current fact>
- **Evidence:** <source, timestamp, exact path/command/result>
- **Impact:** <operational, security, data, cost, or customer effect>
- **Root cause or first wrong component:** <only when supported>
- **Fix:** <smallest direct remediation>
- **Validation:** <how to prove the issue is resolved>
- **Effort/dependencies:** <S/M/L and prerequisites>
- **Mutation risk:** <rollback, backup, downtime, or approval needs>

## Findings

### FINDING-001: <verified contextual state>

- **Confidence:**
- **Evidence:**
- **Implication:**

## Opportunities and optimizations

### OPPORTUNITY-001: <optional improvement>

- **Evidence/baseline:**
- **Expected benefit:**
- **Tradeoff:**
- **Experiment or measurement:**
- **Effort:**

## Enhancements

### ENHANCEMENT-001: <net-new capability>

- **Problem enabled or future value:**
- **Why this is not a current defect:**
- **Dependencies and scope:**
- **Success measure:**

## Cleanup candidates

| Resource | Exact ID/name | Why candidate | Cost/data consequence | Required safety gate | Proposed action |
|---|---|---|---|---|---|

## Backup and recovery assessment

| Data store | HA | Snapshot | Independent backup | RPO/RTO | Last restore proof | Assessment |
|---|---|---|---|---|---|---|

## Cost and capacity assessment

| Driver | Provisioned | Utilization | Actual or estimate | Waste/risk | Recommendation |
|---|---|---|---|---|---|

## Remediation sequence

### Immediate containment or data safety

1. <Only verified urgent actions>

### Quick reversible fixes

1. <Small, bounded remediation>

### Planned remediation

1. <Coordinated fixes>

### Optional optimization experiments

1. <Measure before committing>

### Independent enhancements

1. <Net-new capability kept separate from defect repair>

## Contradictions, unknowns, and blocked evidence

- <State what cannot be concluded and the exact next query/evidence needed.>

## Verification plan

- <Provider state checks>
- <Service-level checks>
- <Data/restore checks>
- <Cost checks>
- <Rollback checks>

## Sources and command ledger

- <Repository paths, provider commands, dashboards, first-party docs, timestamps, and access notes>
