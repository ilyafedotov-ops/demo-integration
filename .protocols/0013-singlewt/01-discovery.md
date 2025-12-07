# Step 01: Project discovery and constraints alignment

## Briefing
- **Goal:** Understand repo layout, tooling, and specific needs for the single worktree task before making changes.
- **Key files:**
  - `package.json` or equivalent build manifest (if present)
  - `README.md` / `CONTRIBUTING.md`
  - Existing CI configs (e.g., `.github/workflows`, `.gitlab-ci.yml`)
- **Additional info:** Keep paths relative to PROJECT_ROOT. Capture any quirks (custom scripts, monorepo tools, language version).

## Sub-tasks
1. Map repository layout:
   - From PROJECT_ROOT, run `ls` to capture top-level files/dirs and note language/framework indicators.
   - If unclear, run `rg --files` to spot manifests/configs (e.g., `package.json`, `pnpm-lock.yaml`, `poetry.lock`, `tsconfig`, `Makefile`, `docker-compose*`, `src/`). Record notable directories relative to PROJECT_ROOT in `log.md`.
2. Identify package manager, runtimes, and scripts:
   - Locate manifests/lockfiles/version pins (`package.json`, `pnpm-lock.yaml`, `yarn.lock`, `requirements.txt`, `pyproject.toml`, `.nvmrc`, `.tool-versions`, `Dockerfile`, `Makefile`).
   - Deduce primary package manager/runtimes and canonical install commands; enumerate lint/test/typecheck/build scripts or targets (manifest or Makefile). Note custom tooling (monorepo tools, husky/lint-staged, codegen).
   - Record commands and relevant paths in `log.md`.
3. Capture contribution standards:
   - Read `README.md`, `CONTRIBUTING.md`, and nearby docs (e.g., `docs/`, `.github/`) for coding style, branching/commit rules, review expectations, and required local checks.
   - Summarize required conventions and their locations in `log.md`.
4. Extract CI expectations:
   - Inspect `.github/workflows/*`, `.gitlab-ci.yml`, or other CI configs to list required jobs/checks, triggers (push/PR), matrix versions, artifacts, and required env vars/secrets.
   - Note which checks should be mirrored locally (lint/typecheck/test/build) and any gating requirements; capture in `log.md`.
5. Clarify "Single worktree test" scope:
   - Review protocol docs/issues/tasks in this repo to align on the expected deliverable for Step 2, consistent with `plan.md` goals.
   - Enumerate concrete areas to change/validate next (target files/modules, commands to run, outputs to provide), and log any open questions.
6. Record findings and prep context (no commit yet):
   - Append discovery notes/decisions to `log.md` under this step, including command references.
   - Update `context.md`: set `Current Step` to `2`, `Status` to `In Progress`, and `Next Action` to start Step 2 implementation.

## Workflow
1. Execute sub-tasks.
2. Verify: run `lint`, `typecheck`, `test` (scope as needed). Fix failures or note blockers.
3. Fix/record:
   - Add to `log.md` what/why (non-obvious decisions).
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "chore(protocol): discovery notes [protocol-0013/01]"`. Push.
5. Report to user using the step report format.
