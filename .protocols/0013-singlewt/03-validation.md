# Step 03: Validate, document, and prep PR

## Briefing
- **Goal:** Ensure changes are validated, documented, and ready for review.
- **Key files:**
  - Tests added/updated in Step 2
  - `README.md` / project docs if updated
  - CI configuration if touched
- **Additional info:** Make sure log/context reflect latest state.

## Sub-tasks
1. Run validation commands from the repo root in order: `lint`, then `typecheck`, then `test`; if any fail, fix the code/config and rerun until all pass; capture pass/fail details (command + brief note) for `log.md`.
2. Inspect `git diff` for style/consistency: confirm formatting, naming, error handling, and adherence to project conventions; apply small cleanups as needed and ensure diffs stay focused on Step 2 scope.
3. If behavior or setup changed, update docs accordingly: adjust `README.md`/project docs, usage notes, and add/change changelog entry if the repo uses one; ensure any new instructions are actionable.
4. Update `.protocols/0013-singlewt/log.md` with validation outcomes, key decisions, and any reviewer-facing notes (include command statuses and rationale for notable changes).
5. Update `.protocols/0013-singlewt/context.md`: set `Current Step` to `4`, `Status` to `In Progress`, and `Next Action` to finalize and mark PR ready; save but do not commit yet.

## Workflow
1. Execute sub-tasks.
2. Verify: run `lint`, `typecheck`, `test` (scope as needed). Fix failures.
3. Fix/record:
   - Add to `log.md` what/why (non-obvious decisions).
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "chore: validate and document [protocol-0013/03]"`. Push.
5. Report to user using the step report format.
