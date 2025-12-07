# Step 04: Update docs and release notes

## Briefing
- **Goal:** Document the new codemachine timeout flags, defaults, and usage; update changelog/release notes as needed.
- **Key files:**
  - `README.md` or relevant CLI docs in `docs/`
  - `CHANGELOG.md` or release notes file
  - Any examples/sample configs referencing codemachine
- **Additional info:** Provide concise examples showing default behavior and custom timeout usage; mention any breaking/behavioral changes.

## Sub-tasks
1. Identify all user-facing docs that mention codemachine runs/flags (CLI reference, README sections, docs pages) and note existing timeout/default language to update.
2. Add/update the CLI docs to describe the new timeout flag(s): flag names, defaults, valid ranges/validation rules, and how they interact with existing behavior.
3. Add concise usage examples for the timeout flag(s): one showing default behavior (no flag) and one with explicit timeout value (CLI and config form if supported).
4. Update sample configs or example scripts to include the timeout flag(s) where relevant; ensure narratives stay consistent with the new defaults/behavior.
5. Add a changelog/release-note entry summarizing the timeout flag addition, defaults/behavioral changes, and any actions required by users.
6. Cross-check links/anchors/references in updated docs to ensure navigation and formatting remain correct.
7. Run applicable checks for docs changes (`lint`, `typecheck`, `test`, plus any docs formatter if present) and fix issues.
8. Add a `log.md` entry capturing the documentation changes, rationale, and any open questions.

## Workflow
1. Execute sub-tasks.
2. Verify: run `lint`, `typecheck`, `test` (scope as needed). Fix failures.
3. Fix/record:
   - Add to `log.md` what/why (non-obvious decisions).
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "feat(scope): subject [protocol-0011/04]"`. Push.
5. Report to user using the step report format above.
