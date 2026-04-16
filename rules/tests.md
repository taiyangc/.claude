# Test Handling

## Never ignore failing tests — even pre-existing ones

When running tests (unit, integration, type-check, lint, etc.) any failure that appears in the output must be fixed, regardless of whether the failure predates the current changes. Never say "not modified by current changes", "pre-existing failure", or "unrelated to my work" as a reason to skip fixing a test.

A failing test that was allowed to go unaddressed is often *why* a bug was able to slip through in the first place. The cost of fixing stale tests now is far less than the cost of a production bug later. Leaving red tests in the repo also erodes trust in the suite — once some failures become "acceptable", the bar for new failures quietly drops.

### What to do when you see a failing test

1. **Fix it** — ideally restore the test so it passes against current code.
2. **If the test is genuinely dead** (references deleted constants, exercises removed features, points to a file that no longer exists), delete the test file in the same commit. Do not leave it in the tree with a skip/xfail marker unless the user explicitly asks for it.
3. **If fixing requires a product decision** (e.g. "this assertion about a UX rule is now ambiguous"), surface it to the user and propose both a fix and a deletion. Don't let ambiguity be a reason to defer.

### Scope

This applies to every test the repo ships — including tests in sibling packages, shared packages, or integration suites that are currently red. Before declaring a task complete, the test suites that were failing at the start of the session should either be green or have been deleted for a documented reason.

### When reporting status

Do not report "build/typecheck passes, except for pre-existing errors I didn't touch". That framing implicitly asks the user to accept the red state. Instead, fix the failures and report a fully green suite, or flag the specific failure to the user with a proposed resolution so they can decide.
