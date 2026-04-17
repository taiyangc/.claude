# Solidity Standards

## Build
- For foundry-based projects, always attempt to fix warnings and notes after `forge build`.
- When fixing warnings, always remove unused things instead of simply commenting out.

### Never suppress forge-lint findings by any means
Every path below is forbidden. The only acceptable response to a warning or note is a **real code change** that removes the dangerous pattern.

- **Inline suppressions forbidden**: no `forge-lint: disable-next-line(…)`, `forge-lint: disable-line(…)`, `forge-lint: disable(…)`, or any other inline hint.
- **Project-level suppressions forbidden**: no `[lint] exclude_lints`, no `[lint] severity`, no `[lint] lint_on_build = false`, no other `foundry.toml` flag that silences a lint.
- **Selective-run workarounds forbidden**: do not invoke `forge lint --only-lint …`, `forge lint --severity …`, or any flag that skips the default lint set as a workaround for a specific finding.

Real code fixes for common findings:
- `unsafe-typecast` → use `SafeCast.toUintXX` / `SafeCast.toIntXX` from OpenZeppelin, or narrow the source type, or add an explicit `require(x <= type(uintXX).max)` guard before the cast — never the disable-hint.
- `unsafe-cheatcode` → restructure to not invoke the cheatcode. Move JSON/file reads to build-time codegen (e.g. a generator script reads the JSON and emits a Solidity constants file that the script imports), or replace the cheatcode with a safer one (`vm.envAddress` / `vm.envUint` are not flagged), or pass the data in via constructor / CLI args.

"Fix warnings" requests from the user are NOT blanket authorization to suppress. They are requests for compliant code. If you cannot find a real code fix, **stop and ask the user** — do not reach for suppression.

Also prohibited with the same framing:
- `--ir-minimum` to work around stack-too-deep or via_ir issues. Fix stack depth at the source (scoped blocks, helper extraction) instead.
- Blanket compiler-warning ignores (`--ignored-error-codes …` used as a silencer rather than a scoped opt-out for vetted library paths).

## Code
- require() should always use custom errors.
- Do not use the if-then-revert pattern, always do a require() pattern.
- Never implement a looped array item removal since the array can grow indefinitely, always do a map removal for O(1).

## Best Practices
- Never have a separate internal functions section - leave internal function implementation at the nearest locality where it is used.
