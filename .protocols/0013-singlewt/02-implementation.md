# Step 02: Implement requested changes

## Briefing
- **Goal:** Apply code/config changes required for the single worktree task based on discovery findings.
- **Key files:** Pull from Step 1 outputs (e.g., noted source files/configs/workflows) before editing.
- **Additional info:** Keep scope minimal; align with existing patterns and linters.

## Sub-tasks
1. Restate the concrete requirement in `log.md`: summarize what must change and why, referencing the Step 1 findings and specific files/modules touched.
2. Inspect the targeted files identified in Step 1; note existing patterns (style, helpers, lint rules) to mirror in the implementation.
3. Implement the minimal code/config/doc updates to meet the requirement:
   - Edit the identified files only; keep changes scoped and consistent with current conventions.
   - Add concise inline comments only where logic is non-obvious.
4. Add or adjust automated tests to cover the new/changed behavior (positive, negative, boundary), reusing existing helpers and test layouts; ensure fixtures/mocks stay in sync.
5. Run project checks in this order: `lint`, `typecheck`, then `test`; iterate on code/tests until all pass cleanly.
6. Update `context.md`: set `Current Step` to `3`, `Status` to `In Progress`, and `Next Action` to validation/documentation; do not commit this update yet.

## Workflow
1. Execute Sub-tasks 1–6 in order; keep edits within the worktree.
2. Verify results: rerun `lint`, `typecheck`, and `test` after fixes to confirm they are green.
3. Record decisions: append to `log.md` the what/why of changes and any non-obvious choices; ensure `context.md` reflects the next step; confirm `main` has no stray files from this branch.
4. Commit with `git add .` then `git commit -m "feat: implement single worktree changes [protocol-0013/02]"`; push.
5. Report to the user using the prescribed step report format.
