# 0013 — singlewt

## ADR-style Summary:
- **Context**: Need to execute "Single worktree test" under TasksGodzilla protocol using the repo in a dedicated worktree.
- **Problem Statement**: Ensure disciplined workflow with isolated protocol artifacts, clear steps, and predictable delivery for the single worktree task.
- **Decision**: Follow a structured, stepwise protocol with committed plan files, discovery-first execution, implementation with checks, and formal wrap-up.
- **Alternatives**: Ad-hoc hacking without protocol; skipping discovery; direct main-branch edits.
- **Consequences**: Predictable progress, traceable changes, and easier review; overhead of protocol steps.

---

## High-Level Plan:
This section is a **contract**; do not change during implementation.

- **[Step 0: Prepare and lock plan](./00-setup.md)**: Create and commit protocol artifacts.
- **[Step 1: Project discovery and constraints alignment](./01-discovery.md)**: Inspect repo, tooling, and requirements for the single worktree task.
- **[Step 2: Implement requested changes](./02-implementation.md)**: Apply code/config updates per findings; keep scope lean.
- **[Step 3: Validate, document, and prep PR](./03-validation.md)**: Run checks/tests, update docs/logs, push updates.
- **[Step 4: Finalize](./04-finalize.md)**:
  * Mark PR Ready
  * Close out work

---

## Protocol Workflow (How to execute)
Follow `High-Level Plan` and this cycle for each step.

- **PROJECT_ROOT**: /home/ilya/Documents/dev-pipeline/Projects/github.com/ilyafedotov-ops/demo-integration
- **CWD (worktree)**: /home/ilya/Documents/dev-pipeline/Projects/github.com/ilyafedotov-ops/worktrees/tasksgodzilla-worktree
- **Protocol folder**: /home/ilya/Documents/dev-pipeline/Projects/github.com/ilyafedotov-ops/worktrees/tasksgodzilla-worktree/.protocols/0013-singlewt

All work happens in the worktree (CWD).

### A. Before a new step (restore context)
1. Read `Current Step` from `context.md`.
2. Open the step file (e.g., `01-discovery.md`).
3. Ensure previous changes are committed.

### B. During the step (execute)
1. Do the sub-tasks in the step file.
2. Do **not** change plan files (`plan.md`, `XX-*.md`). They are the contract.
3. Follow Generic Principles below.

### C. After the step (verify & fix)
1. Run checks: `typecheck`, `lint`, `test`. Fix until green.
2. Add a `log.md` entry describing what and why (include commit ID).
3. Rewrite `context.md` for the next step.
4. Verify `main` has no stray files from our branch. Commit with `type(scope): subject [protocol-0013/YY]`. Push.
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
- TBD (capture relevant docs discovered during Step 1)
