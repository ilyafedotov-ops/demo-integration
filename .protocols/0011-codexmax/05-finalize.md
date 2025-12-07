# Step 05: Finalize

## Briefing
- **Goal:** Ensure the branch is ready for review/merge with all checks green and protocol artifacts updated.
- **Key files:**
  - `.protocols/0011-codexmax/context.md`
  - `.protocols/0011-codexmax/log.md`
  - PR description/body
- **Additional info:** Confirm no extra files are left, and the PR is marked Ready for Review with a clear summary.

## Sub-tasks
1. Re-run full verification suite and ensure green
   - Run `npm test` (or project equivalent) for unit/integration; capture results.
   - Run `npm run lint` and `npm run typecheck` (or equivalents); fix any failures.
   - Re-run any previously failing checks to confirm resolution.
2. Review git status for stray/untracked files; clean or commit as appropriate
   - Run `git status -sb` to list changes/untracked files.
   - Remove or stash unintended files; ensure only intentional changes remain staged/unstaged.
   - Confirm no stray files from this branch exist on `main` (compare if needed).
3. Update protocol artifacts
   - In `.protocols/0011-codexmax/context.md`: set Status to Done, set Current Step to 6/Complete, and note Next Action as none or follow-up if pending.
   - In `.protocols/0011-codexmax/log.md`: add final entry summarizing work and include latest commit hash.
   - Ensure protocol folder paths are referenced correctly in notes/PR body.
4. Push latest commits and prepare PR
   - Stage and commit remaining changes with message `feat(scope): subject [protocol-0011/05]`.
   - Push branch; verify remote is updated.
   - Ensure PR description references `.protocols/0011-codexmax/` and mark PR Ready for Review.
5. Prepare final report for the user
   - Collect summary of what/where/why, including log reference.
   - List checks run (lint/typecheck/test) with pass/fail status.
   - Record git details: PR link, branch name, commit message(s), push status, main-branch cleanliness.
   - Note working directory path and protocol status (completed) for the report.

## Workflow
1. Execute sub-tasks.
2. Verify: run `lint`, `typecheck`, `test` (scope as needed). Fix failures.
3. Fix/record:
   - Add to `log.md` what/why (non-obvious decisions).
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "feat(scope): subject [protocol-0011/05]"`. Push.
5. Report to user using the step report format above.
