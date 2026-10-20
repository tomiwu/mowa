# TASK

Review the code changes on branch `{{BRANCH}}` and improve code clarity, consistency, and maintainability while preserving exact functionality.

# CONTEXT

## Branch diff

!`git diff {{TARGET_BRANCH}}...{{BRANCH}}`

## Commits on this branch

!`git log {{TARGET_BRANCH}}..{{BRANCH}} --oneline`

# REVIEW PROCESS

1. **Understand the change**: Read the diff and commits above to understand the intent.

2. **Analyze for improvements**: Look for opportunities to:
   - Reduce unnecessary complexity and nesting
   - Eliminate redundant code and abstractions
   - Improve readability through clear variable and function names
   - Consolidate related logic
   - Remove unnecessary comments that describe obvious code
   - Avoid nested ternary operators - prefer switch statements or if/else chains
   - Choose clarity over brevity - explicit code is often better than overly compact code

3. **Check correctness**:
   - Does the implementation match the intent? Are edge cases handled?
   - Are new/changed behaviours covered by tests?
   - Are there unsafe casts, force unwraps, `try!`, `as!`, singletons, `@unchecked Sendable`, or unchecked assumptions?
   - Does the change introduce injection vulnerabilities, credential leaks, or other security issues?

4. **Maintain balance**: Avoid over-simplification that could:
   - Reduce code clarity or maintainability
   - Create overly clever solutions that are hard to understand
   - Combine too many concerns into single functions or components
   - Remove helpful abstractions that improve code organization
   - Make the code harder to debug or extend

5. **Follow docs/PRD.md** (mowa spec).

6. **Apply project standards**: Follow the coding standards in @.sandcastle/CODING_STANDARDS.md and in `docs/CODING_STANDARDS.md` (when it exists). `docs/CODING_STANDARDS.md` has priority.

7. **Preserve functionality**: Never change what the code does - only how it does it. All original features, outputs, and behaviors must remain intact.

# RULES

- Every function must have a CRAP score less than 4. Make methods small and well tested.
- Do not push. Do not open a PR. Do not close the issue.
- Do not edit `docs/PRD.md` or `.sandcastle/`.
- You can edit `.github/workflows/ci.yml`. Keep the job ids `format`, `lint`, `build`, `test` and `crap`. Branch protection requires them. Do not rename or remove these jobs. The `test` job runs the tests. The `crap` job runs `scripts/crap.sh`. You can add new jobs.
- In `ci.yml`, do not skip a step when a file is missing. The tests always run. `scripts/crap.sh` always runs, and the job fails if the script is missing.

# EXECUTION

If you find improvements to make:

1. Make the changes directly on this branch
2. Run `swift format lint --strict --recursive .`, `swiftlint lint --strict` and `swift test` for Linux packages to ensure nothing is broken
3. Commit describing the refinements. Write the commit message in English, in ASD-STE100 Simplified Technical English.

If the code is already clean and well-structured, do nothing.

Once complete, output <promise>COMPLETE</promise>.
