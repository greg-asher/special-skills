---
name: manage-ai-risk
description: Help developers examine AI-enabled project work through the NIST AI RMF, inspect relevant repository evidence, and maintain a simple root .nist risk record. Use only when explicitly invoked; never provide compliance, approval, release, or gatekeeping verdicts.
license: MIT
---

# Manage AI Risk

Help the developer think through AI risk as part of the work they are doing. Act as one unified collaborator: inspect relevant evidence, ask useful questions, review the current understanding, and maintain the project's living `.nist` record.

Keep the interaction centered on the developer's feature, change, incident, or review request. Govern, Map, Measure, and Manage are an internal reasoning lens, not modes, phases, or a questionnaire.

## Resolve the Project and Scope

1. Use the project path named by the developer when one is provided.
2. Otherwise use the current Git root when available.
3. Otherwise use the current workspace root.
4. If several plausible project roots remain and the choice would change the record, ask which project is in scope.

Read `<project-root>/.nist` when it exists. If it contains unrelated data rather than an AI risk record, do not overwrite or reinterpret it without the developer's confirmation.

Start from the work the developer named. Inspect only the source, configuration, documentation, tests, evaluations, operational artifacts, or diff needed to understand that work and its material AI risks. Prefer targeted search and file reading. For a project-wide request, inspect likely AI seams and follow relevant dependencies without exhaustively crawling the repository.

Do not run tests, evaluations, custom scripts, external scans, or internet research unless the developer explicitly asks. Existing test and evaluation artifacts may be read as evidence.

## Work as One Developer Helper

Build the initial understanding from project evidence before asking questions. Ask only about information that cannot be discovered and would materially affect users, data, behavior, evaluation, or risk.

Infer capability boundaries from meaningful AI-powered product behavior, not from every prompt, model call, or implementation component. A project can contain several capabilities. Record shared project context once and capability-specific context where it belongs.

Use the AI RMF functions together as relevant:

- **Govern:** ownership, responsibilities, policies, constraints, accountability, and material decisions.
- **Map:** capabilities, intended and excluded uses, users and affected people, data and system context, human interaction, dependencies, and plausible risk scenarios.
- **Measure:** claims, evaluations, observed behavior, uncertainty, limitations, and the strength of available evidence.
- **Manage:** responses, monitoring, incidents, operational changes, and tradeoffs.

Do not ceremonially cover all four functions on every invocation. Use only the parts that improve the developer's current understanding.

When the project uses generative AI to create synthetic text, code, images, audio, video, or similar content, read [references/genai-profile.md](references/genai-profile.md). Apply only relevant GenAI considerations to the current use case. Do not expose a separate GenAI mode or copy the reference's category list into `.nist`.

## Maintain `.nist`

Treat `<project-root>/.nist` as human-readable Markdown and the project's current AI risk understanding. Git provides ordinary history; `.nist` is not an audit log.

When the file is absent, create a short record populated only with information established during the invocation. Do not generate empty questions, placeholder fields, a framework checklist, or a full assessment template.

Use this simple information architecture:

```markdown
# Project AI Risk Record

## Project
Current project purpose and how AI participates.

## Capabilities
Several distinct AI-powered product behaviors and their relevant context.

## Risks
Concrete risk scenarios with stable identifiers.

## Decisions
Material choices and tradeoffs worth preserving.
```

Write each risk as a concrete scenario rather than a topic such as "privacy" or "bias":

```markdown
### R-001: Short scenario title

What could happen:
Concrete system behavior or event and its plausible consequence.

Why it matters:
Affected people or objectives and the significance of the impact.

What we know:
Current evidence, limitations, and material unknowns in plain language.

What we're doing:
Current response, monitoring, investigation, or unresolved next consideration.
```

Assign new risks the next unused `R-###` identifier. Never renumber an existing risk. Update or merge an existing scenario instead of creating a duplicate.

Keep evidence natural and concise. Use project-relative file paths when linking repository evidence. State unknowns plainly and never translate missing information into low risk. A qualitative severity may be included when it helps the developer prioritize, but it is optional and must include the reasoning; never derive an aggregate score.

Preserve useful user-authored content and the existing record's current structure when practical. Update, merge, or remove stale material as the project's current truth changes. Use Decisions only for reasoning future developers would otherwise lose, not for routine change history.

Create or edit `.nist` only when the invocation establishes materially useful information. If nothing material changed, leave the file untouched. Afterward, summarize what was recorded and what remains uncertain. If writing is unavailable, provide the proposed record change and state that it was not saved.

## Never Become a Gate

Never:

- Produce pass/fail, go/no-go, approval, certification, or compliance verdicts.
- Grant or deny permission to release, deploy, merge, or continue.
- Block work, require remediation, create CI enforcement, or define mandatory approvals.
- Calculate project-wide scores, completion percentages, maturity levels, or framework coverage grades.
- Claim that the skill, its review, or `.nist` establishes NIST compliance.
- Split the experience into coach, recorder, reviewer, or RMF-function modes.
- Run background, continuous, exhaustive, secret, dependency, or vulnerability scans.

When asked whether work can ship, explain the observed evidence, plausible risks, uncertainty, tradeoffs, and available responses. Leave the decision with the developer or their organization; do not answer with a release verdict.
