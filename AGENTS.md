<!-- model-router:start -->
# Model router (quality first, cost second)

Route every **part** of a non-trivial task to one of the eight custom agents in `~/.codex/agents/` — `scout`, `researcher`, `builder`, `tester`, `writer`, `verifier`, `architect`, `auditor` — each pinned to its own model and reasoning effort. Re-decide the tier at every checkpoint. Never trade correctness for cost. Skip routing for trivial one-step tasks; the router must never cost more than the work.

## 1. Classify (no tools, 30 seconds)
Score 0–2 on four axes and sum:
- **Ambiguity**: fully specified 0 · some judgment 1 · goal known, approach unknown 2
- **Blast radius**: scratch/reversible 0 · one module 1 · billing, auth, data, deploy, public API, irreversible 2
- **Novelty**: pattern exists in repo 0 · adapt a pattern 1 · unfamiliar code or new architecture 2
- **Verification**: tests/lint prove it 0 · partially testable 1 · only human review can confirm 2

0–1 → **scout** · 2–4 → **builder** · 5–8 → **architect**.
**Overrides:** blast radius 2 → architect always, and STOP for human review before any edit. Legal/financial/medical substance → architect. User says "just do it quickly" on a reversible task → drop one tier.

## 2. Split before routing
investigate + plan → architect (stop for review if blast ≥ 1) · external facts, library/API docs, versions → researcher (sourced, CONFIRMED/LIKELY/UNKNOWN) · find/grep/summarize → scout, spawned in parallel · write the tests → tester (from the brief, never the builder) · implement → builder · prose: docs, README, copy → writer (from an approved outline) · verify → verifier (never the agent that wrote the code) · final gate on a blast-2 change → auditor (SHIP / DO NOT SHIP).

## 3. Delegate with a self-contained brief
Spawn the named agent. Every brief contains: GOAL (one sentence) · CONSTRAINTS · INPUTS (exact paths) · DEFINITION OF DONE (checkable) · EFFORT ("answer directly" for scout; "reason exhaustively" only for architect on blast-2 / unknown-cause work) · RETURN (compact shape: findings list, diff summary, verdict). Never forward conversation history. Say the routing in one line before starting:
`Routing: architect → plan (stop) · builder → implement · verifier → check`.

## 4. Effort follows the tier
Effort is pinned in each agent file (scout low · researcher and writer medium · builder, tester, verifier high · architect xhigh · auditor max). Raise it within a tier only when reasoning is the bottleneck for that part: builder on concurrency, migrations, or edge-case tests → ask it to reason carefully about edge cases before editing; architect on blast-2 or unknown-cause debugging → ask for exhaustive reasoning; scout → never.

## 5. Re-route at every checkpoint (mid-task switching)
Tiers belong to parts, not to the task. A checkpoint is: plan approved, a spawned agent returned, a verdict came in, a new fact appeared, the user changed the ask. Re-score the next part at each one.
- **Shift UP:** unknown cause, unfamiliar architecture, or a trade-off appears → architect. Anyone touches billing/auth/data/deploy → stop, blast 2, architect, wait for the human. Scout says "can't tell without reading deeply" → builder. Builder fails verification once → retry builder with raised effort if it is a contained slip, otherwise straight to architect. Fails twice → architect, no exceptions. Verifier finds a BLOCKER it can't explain → architect root-causes before anyone patches. Researcher returns UNKNOWN on a fact the plan depends on → architect decides; never let a builder assume. Auditor says DO NOT SHIP → back to architect with the findings; the builder does not patch an audit failure directly.
- **Shift DOWN:** plan approved → builder. A part becomes a lookup, rename, grep, or summary → scout. A retry passed → the next part resumes its natural tier; escalation never sticks to the whole task. Verification is mechanical → verifier at default. Remaining work is prose → writer, with the verifier checking claims against code.
- **Never shift down:** inside a part that is still running; below the tier of the code being debugged (a billing bug stays architect even for a one-line fix); on a part that already failed at that tier; on anything the user will ship, publish, or send to another person — always run the verifier.
- Announce every switch in one line: `Re-route: builder → architect (cause unknown after failed patch)`. Say nothing if unchanged.
- The primary session cannot change its own model or effort; that is the user's `/model`. Do not suggest moving the primary session to a cheaper model to save usage.

## Anti-patterns
Architect used as a typist · effort as reassurance (max on everything) · verifier = author · scout dumping file contents · silent downgrade inside a part · sticky escalation · routing the trivial.
<!-- model-router:end -->
