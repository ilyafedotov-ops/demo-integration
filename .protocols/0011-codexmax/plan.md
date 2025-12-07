# 0011 — codexmax

## ADR-style Summary:
- **Context**: We need to introduce codemachine flags that allow configuring timeout behavior, ensuring executions fail fast or respect user-defined limits. The work happens in the demo-integration repo within the dedicated 0011-codexmax worktree.
- **Problem Statement**: Existing codemachine runs lack configurable timeout control, leading to possible hangs or inconsistent behavior; we must add flags and wiring with sensible defaults and validation.
- **Decision**: Add timeout-related CLI/config flags for codemachine, propagate through parsing and runtime execution, validate inputs, and document usage with supporting tests.
- **Alternatives**: Rely solely on hardcoded timeouts; use environment variables only; implement per-task config instead of CLI flags; defer change.
- **Consequences**: Better operator control and reliability; requires coordinated updates across parsing, runtime, tests, and docs; possible behavior change if defaults shift.

---

## High-Level Plan:
This section is a **contract**; do not change during implementation.

- **[Step 0: Prepare and lock plan](./00-setup.md)**: Create and commit protocol artifacts.
- **[Step 1: Audit codemachine flags and timeout requirements](./01-discovery.md)**: Map current flag parsing, config flow, timeout handling, and test/docs coverage.
- **[Step 2: Implement timeout flag support in codemachine](./02-implementation.md)**: Add/validate flags, wire to runtime, and enforce defaults.
- **[Step 3: Add/adjust tests for timeout flags](./03-tests.md)**: Cover parsing, validation, runtime behavior, and regressions.
- **[Step 4: Update docs and release notes](./04-docs.md)**: Document flags, usage examples, and changelog entries.
- **[Step 5: Finalize](./05-finalize.md)**:
  * Mark PR Ready
  * Close out work

---

## Protocol Workflow (How to execute)
Follow `High-Level Plan` and this cycle for each step.

- **PROJECT_ROOT**: /home/ilya/Documents/dev-pipeline/Projects/github.com/ilyafedotov-ops/demo-integration
- **CWD (worktree)**: /home/ilya/Documents/dev-pipeline/Projects/github.com/ilyafedotov-ops/worktrees/0011-codexmax
- **Protocol folder**: /home/ilya/Documents/dev-pipeline/Projects/github.com/ilyafedotov-ops/worktrees/0011-codexmax/.protocols/0011-codexmax

All work happens in the worktree (CWD).

### A. Before a new step (restore context)
1. Read `Current Step` from `context.md`.
2. Open the step file (e.g., `01-step-name.md`).
3. Ensure previous changes are committed.

### B. During the step (execute)
1. Do the sub-tasks in the step file.
2. Do **not** change plan files (`plan.md`, `XX-*.md`). They are the contract.
3. Follow Generic Principles below.

### C. After the step (verify & fix)
1. Run checks: `typecheck`, `lint`, `test`. Fix until green.
2. Add a `log.md` entry describing what and why (include commit ID).
3. Rewrite `context.md` for the next step.
4. Verify `main` has no stray files from our branch. Commit with `type(scope): subject [protocol-NNNN/YY]`. Push.
5. Report to the user in the format:
<report_format>
(Protocol, step):

**Done**: what/where/why (also in Log).

**Checks**: which ran (lint/typecheck/test), pass/fail, why.

**Git**: PR link; current branch; commit message; push status; main-branch cleanliness check.

**Working directory**: absolute CWD path.

**Protocol status**: where we are and what’s next.
</report_format>

---

## Generic Principles (MUST follow, shared)
- Balance & simplicity; avoid overengineering.
- No legacy; greenfield decisions allowed.
- Respect coding standards/linters/formatters/JSDoc.
- Keep docs current (Memory Bank), atomic.
- Quality tests: positive/negative/boundaries; reuse helpers.
- Detail & decomposition: plans executable without this chat.

---

## Reference Materials
- Project README (`README.md`).
- Existing CLI/command docs under `docs/`.
- Current tests near codemachine components (e.g., `src/**/__tests__` or similar).
- Any config/schema definitions controlling CLI flags.
