# Step 02: Implement timeout flag support in codemachine

## Briefing
- **Goal:** Add configurable timeout flags for codemachine, validate inputs, and wire them through runtime execution with sensible defaults.
- **Key files:**
  - `cli/` (flag definitions and parsing)
  - `src/` (codemachine runtime, timeout handling, configuration mapping)
  - `config/` or type definitions defining CLI/config schemas
- **Additional info:** Ensure backward compatibility: defaults should match current behavior unless explicitly changed; provide clear error messages for invalid values.

## Sub-tasks
1. Reconfirm current default timeout behavior from discovery notes and pick the canonical default constant/unit to preserve existing behavior when no flag is provided.
2. Add CLI flag definition(s) for the timeout (name, alias if any, unit, help text, default) in the codemachine CLI entrypoint and ensure parsing produces a numeric value.
3. Wire environment variable override(s) for the timeout following existing precedence rules (env → CLI → config defaults) and normalize units.
4. Extend config schema/types to include the timeout field with default and description; ensure serialization/deserialization includes it.
5. Implement validation for the timeout input (positive integer, optional upper bound, reject NaN/Infinity) with clear user-facing error messages.
6. Propagate the validated timeout through config loading into runtime options: update constructors/functions to accept the field and adjust all call sites to pass it.
7. Implement runtime enforcement using the configured timeout (e.g., AbortController/Promise.race or existing helper) so executions abort on timeout with consistent error/exit handling.
8. Add concise logging/metrics for timeout triggers (duration, operation context) if instrumentation exists, avoiding noisy output for normal runs.
9. Normalize fallback behavior: centralize the default constant, remove conflicting legacy fallbacks, and verify unspecified flags/env keep current behavior.

## Workflow
1. Execute sub-tasks.
2. Verify: run `lint`, `typecheck`, `test` (scope as needed). Fix failures.
3. Fix/record:
   - Add to `log.md` what/why (non-obvious decisions).
   - Update `context.md`: increment `Current Step`, set `Next Action`.
   - Check `main` for stray files from our branch.
4. Commit: `git add .` then `git commit -m "feat(scope): subject [protocol-0011/02]"`. Push.
5. Report to user using the step report format above.
