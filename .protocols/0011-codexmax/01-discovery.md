# Step 01: Audit codemachine flags and timeout requirements

## Briefing
- **Goal:** Understand existing codemachine flag parsing, timeout mechanisms, and the desired changes to support configurable timeouts.
- **Key files:**
  - `cli/` (flag definitions/commands, if present)
  - `src/` (codemachine implementation and timeout handling)
  - `docs/` (current CLI/config documentation)
- **Additional info:** Capture current default timeout behavior, any environment variables controlling it, and existing tests that cover codemachine execution.

## Sub-tasks
1. Map codemachine CLI surfaces
   - Run `rg "codemachine"` within `cli/` and `src/` to find commands/entrypoints.
   - Open the identified files to list existing CLI flags/options and defaults (note data types and required vs optional).
2. Trace flag parsing into config/state
   - Identify parsing mechanism (e.g., commander/yargs/custom) and note how CLI args flow into config objects/types.
   - Capture any schemas/validators (e.g., zod/JSON schema/manual checks) and where they live; record how unknown/invalid flags are handled.
3. Catalog timeout behavior
   - Search for timeout logic (e.g., `timeout`, `AbortController`, `Promise.race`, `setTimeout`) in `src/`; list call sites and the values used.
   - Record defaults (numeric values/units), sources (hardcoded/ENV/config), and how timeouts are enforced/cleared.
4. Review tests covering CLI/config/runtime
   - Locate suites touching codemachine flags/runtime (e.g., `__tests__`, `test`, or integration/e2e directories).
   - Note helpers/mocks used, coverage of timeout behavior, and gaps relevant to new timeout flags.
5. Review docs/README/changelog references
   - Scan `docs/`, `README.md`, and any changelog/release notes for codemachine mention, especially around timeouts/flags/env vars.
   - Note what is currently documented vs missing for timeout control.
6. Synthesize findings
   - Summarize impacted files, current behavior, risks, and open questions in `log.md` (no code changes).
   - Highlight assumptions to validate in implementation/tests/docs steps.

## Workflow
1. Execute sub-tasks above in order; keep notes of file paths and observed behaviors.
2. Verification: run `lint`, `typecheck`, `test` (or document if skipped and why).
3. Record updates:
   - Add to `log.md` what was found and why it matters.
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "feat(scope): subject [protocol-0011/01]"`. Push.
5. Report to user using the step report format above.
