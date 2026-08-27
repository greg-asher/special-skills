# NIST Generative AI Profile Lens

Read this reference only when the project uses generative AI to create synthetic text, code, images, audio, video, or similar content.

## Basis

This lens summarizes the risk families enumerated in **NIST AI 600-1, Artificial Intelligence Risk Management Framework: Generative Artificial Intelligence Profile** (July 2024), a companion to NIST AI RMF 1.0.

- [NIST publication page](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence)
- [NIST AI 600-1 PDF](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf)
- [NIST AI RMF page](https://www.nist.gov/itl/ai-risk-management-framework)

AI RMF 1.0 is under revision. Use this reference as a practical lens for project reasoning, not as a claim of current compliance or exhaustive coverage.

## GenAI Risk Families

- **CBRN information or capabilities:** Generation may make dangerous chemical, biological, radiological, or nuclear knowledge or design assistance easier to access or synthesize.
- **Confabulation:** Generated content may be confidently presented while false, inconsistent, unsupported, or misleading.
- **Dangerous, violent, or hateful content:** Generation may facilitate harmful instructions, threats, self-harm content, illegal activity, incitement, or hateful material.
- **Data privacy:** Models and applications may expose, infer, memorize, combine, or misuse personal and sensitive information.
- **Environmental impacts:** Training and inference may consume material energy, compute, water, or other environmental resources.
- **Harmful bias or homogenization:** Outputs or performance may amplify harmful disparities, stereotypes, exclusion, monocultures, or reduced diversity.
- **Human-AI configuration:** People may over-rely on, avoid, anthropomorphize, or become emotionally entangled with generated outputs or systems.
- **Information integrity:** Generation may lower the cost and increase the scale of misinformation, disinformation, impersonation, or unverifiable content.
- **Information security:** GenAI may expand attack surfaces, leak protected system information, or assist phishing, malware, exploitation, and control circumvention.
- **Intellectual property:** Inputs or outputs may expose trade secrets or reproduce protected, licensed, trademarked, or copyrighted material without appropriate authorization.
- **Obscene, degrading, or abusive content:** Generation may create or distribute abusive sexual content, including nonconsensual intimate imagery or child sexual abuse material.
- **Value chain and component integration:** Opaque models, datasets, providers, tools, and downstream dependencies may hide provenance, supplier, security, or accountability problems.

## How to Apply the Lens

Select only risk families that are materially plausible for the capability and use context. A category name alone is not a risk scenario.

For a relevant family:

1. Connect it to concrete project behavior, users, affected people, data, dependencies, or operating conditions.
2. Inspect available project evidence before asking the developer for context.
3. Record a risk only when a plausible scenario can explain what could happen and why it matters.
4. Capture current evidence, unknowns, and responses in the ordinary `.nist` risk shape.

Do not score category coverage, require every category to appear, or copy this list into `.nist`. Do not import NIST suggested actions as mandatory controls or release conditions.
