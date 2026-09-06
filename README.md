# model-router for Codex

Eight custom Codex subagents plus a set of routing rules for `AGENTS.md`. Each **part** of a task goes to the agent whose model *and* reasoning effort fit it, and the tier is re-decided at every checkpoint while the task is running. Quality-first by default. Saves tokens by keeping the top model on decisions and everything else on the tier that can do it without a retry.

This is the Codex port of [model-router for Claude Code](https://github.com/NathalieChouLab/model-router). Same rubric, same checkpoint rules, native Codex subagents.

## Tiers

| Agent | Model | Effort | Sandbox | Does |
|---|---|---|---|---|
| `scout` | gpt-5.6-luna | low | read-only | grep, locate, summarize. Returns `path:line — fact`, never file dumps |
| `researcher` | gpt-5.6-luna | medium | read-only | external facts: library/API docs, versions, platform behaviour, marked CONFIRMED / LIKELY / UNKNOWN with sources |
| `builder` | gpt-5.6-sol | high | workspace-write | implements an agreed plan, runs the check that proves it |
| `tester` | gpt-5.6-sol | high | workspace-write | writes and runs the tests from the brief, independently of the builder |
| `writer` | gpt-5.6-sol | medium | workspace-write | prose from an approved outline: README, docs, changelog, UI and marketing copy |
| `verifier` | gpt-5.6-sol | high | read-only | adversarial review of someone else's change; `PASS`/`FAIL` with evidence |
| `architect` | gpt-6-astra | xhigh | read-only | plans and decisions; anything with blast radius 2 (billing, auth, data, deploy) |
| `auditor` | gpt-6-astra | max | read-only | final gate for blast radius 2: `SHIP` / `DO NOT SHIP`, with rollback check |

Model names are whatever your `/model` picker lists. Swap them at install time with env vars or edit the `model =` line in each agent file afterwards.

## How it routes

1. **Classify** on four axes, 0–2 each: ambiguity, blast radius, novelty, verification. Sum → scout (0–1), builder (2–4), architect (5–8). Blast radius 2 overrides everything and stops for human review.
2. **Split** mixed tasks so each part runs at its own tier: architect plans, researcher confirms external facts, tester writes tests, builder implements, writer does the prose, scouts grep in parallel, verifier checks (never the author), auditor gates blast-radius-2 changes.
3. **Delegate** with a self-contained brief: goal, constraints, files, definition of done, return shape.
4. **Re-route at every checkpoint.** Plan approved → builder. Unknown cause found → architect. Builder fails verification → raise effort, then model. Retry passed → next part drops back to its natural tier. Every switch is logged: `Re-route: builder → architect (cause unknown)`.
5. **Skip routing** for trivial one-step tasks.

Domain rubrics, the brief template, anti-patterns, and seven worked examples are in `references/`.

## Install

```bash
git clone https://github.com/NathalieChouLab/model-router-codex.git
cd model-router-codex && ./install.sh
codex doctor
```

The installer copies the eight agents to `~/.codex/agents/` (backing up existing files) and appends the router rules to `~/.codex/AGENTS.md` between `model-router:start/end` markers, so re-running it updates in place.

Different models available? Pin them at install time:

```bash
SCOUT_MODEL=gpt-5.4-mini RESEARCHER_MODEL=gpt-5.4-mini BUILDER_MODEL=gpt-5.5 TESTER_MODEL=gpt-5.5 \
WRITER_MODEL=gpt-5.5 VERIFIER_MODEL=gpt-5.5 ARCHITECT_MODEL=gpt-5.5 AUDITOR_MODEL=gpt-5.5 ./install.sh
```

Codex subagents are on by default (`agents.enabled`). If you turned them off, set `agents.enabled = true` in `~/.codex/config.toml`.

## Cost-first variant

If usage matters more than retries: scout `gpt-5.4-mini` low, builder and verifier `gpt-5.6-luna` medium, architect `gpt-5.6-sol` high, and in `AGENTS.md` use tiers scout 0–2, builder 3–5, architect 6–8 with escalation only after **two** failed verifications.

## Requirements

Codex CLI with custom subagents (`~/.codex/agents/*.toml`). Verified on codex-cli 0.153.4.

## License

MIT
