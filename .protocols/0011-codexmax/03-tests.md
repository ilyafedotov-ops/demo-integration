# Step 03: Add/adjust tests for timeout flags

## Briefing
- **Goal:** Ensure timeout flags are covered by automated tests for parsing, validation, and runtime behavior.
- **Key files:**
  - `src/**/__tests__` or similar test locations for codemachine and CLI parsing
  - Any integration/e2e harness that runs codemachine
- **Additional info:** Include negative cases (invalid values), boundary tests (0/1/max), and success paths with and without explicit flags.

## Sub-tasks
1. Gather baseline for testing
   - Inspect timeout flag names, defaults, min/max constraints, and error behaviors implemented in Step 02.
   - Locate existing CLI/config parsing and runtime/e2e test suites and fixtures to extend rather than creating redundant harnesses.
2. Unit: CLI/config parsing and validation
   - Add cases for defaults when flags/config are absent.
   - Add positive cases for valid numeric values (CLI and config), including precedence/override behavior and any unit/rounding rules.
   - Add negative cases for invalid inputs (negative/zero if disallowed, non-numeric, above max, conflicting flags) asserting expected messages/status codes.
   - Add boundary cases at minimum and maximum allowed values to confirm acceptance/rejection aligns with validation rules.
3. Runtime/integration behavior
   - Create a slow/blocked operation that should exceed the timeout; assert timeout exit/status, message, and that elapsed time is within tolerance with proper cleanup.
   - Add a normal-speed operation below the timeout; assert success and absence of timeout warnings.
   - Cover default timeout, CLI override, and config override paths, confirming precedence and observed behavior in each.
4. Snapshots/fixtures
   - Refresh CLI help/config output snapshots or textual fixtures touched by new flags; update stored snapshots/expected JSON/YAML to match intentional outputs.
5. Execute tests and stabilize
   - Run targeted suites for CLI/config parsing and runtime/integration; fix failures in tests or code as needed.
   - Run project-wide `test` (plus `lint`/`typecheck` if required by repo norms) to ensure no regressions.
6. Document coverage
   - Record new behaviors and test file references in `log.md`, noting any remaining gaps to revisit.
   - Prepare the `context.md` update for the next step with current status and next action.

## Workflow
1. Execute sub-tasks.
2. Verify: run `lint`, `typecheck`, `test` (scope as needed). Fix failures.
3. Fix/record:
   - Add to `log.md` what/why (non-obvious decisions).
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "feat(scope): subject [protocol-0011/03]"`. Push.
5. Report to user using the step report format above.
