# Step 04: Finalize

## Briefing
- **Goal:** Conclude the protocol by marking the PR ready, ensuring context/log are final, and handing off.
- **Key files:**
  - `.protocols/0013-singlewt/context.md`
  - `.protocols/0013-singlewt/log.md`
  - PR description/body
- **Additional info:** Confirm no pending worktree changes and CI status is green.

## Sub-tasks
1. Open the PR: ensure the description references `.protocols/0013-singlewt/` (link) and reflects the final state; tick required checkboxes; set reviewers/labels as needed; mark PR Ready for Review.
2. Check CI status (UI or `gh pr checks` if available); if any jobs failing or pending, capture reasons/expected outcomes in `log.md` with timestamps.
3. Confirm local cleanliness before edits: run `git status -sb` to ensure only intended Step 4 changes are present; resolve any stray files.
4. Update `.protocols/0013-singlewt/log.md` with a final entry: note PR readiness, CI status, and any exceptions/waivers.
5. Update `.protocols/0013-singlewt/context.md`: set `Current Step` to `done`, `Status` to `Complete`, `Last Action Summary` to the handoff note, and `Next Action` to `Review/merge`.
6. If any files changed since Step 3 (context/log or otherwise), run required checks (`lint`, `typecheck`, `test`) and record results in `log.md`; if no changes since Step 3, note checks as not rerun and why.
7. Stage and commit Step 4 updates if needed: `git add .` then `git commit -m "chore: finalize protocol [protocol-0013/04]"`; push to remote.
8. Perform cleanliness verification post-push: ensure `git status -sb` is clean; confirm no unpushed commits; ensure `main` has no stray files from this branch (inspect if necessary).
9. Prepare the final user report per format: include Done/Checks/Git/Working directory/Protocol status.

## Workflow
1. Execute sub-tasks in order, keeping changes scoped to Step 4.
2. Verify: if any files changed, run `lint`, `typecheck`, `test`; address failures or document exceptions.
3. Fix/record: log decisions in `.protocols/0013-singlewt/log.md`; update `.protocols/0013-singlewt/context.md` to mark completion; ensure `main` remains untouched by branch artifacts.
4. Commit/push: `git add .` and `git commit -m "chore: finalize protocol [protocol-0013/04]"` if there are changes; push to remote.
5. Report to the user using the prescribed step report format.
