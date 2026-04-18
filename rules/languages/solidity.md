# Solidity Standards

## Build
- For foundry-based projects, always attempt to fix warnings AND informational `note[…]`
  findings after `forge build`. There is NO "legitimate patterns" carveout — every
  `note[unsafe-cheatcode]` must be removed by restructuring the code.
- When fixing warnings, always remove unused things instead of simply commenting out.
- `forge build` at HEAD must emit **zero** `note[unsafe-cheatcode]` findings. CI
  enforces this via the `zero-notes assertion` step.

### Never suppress forge-lint findings by any means
Every path below is forbidden. The acceptable response to a **warning** is always a
**real code change** that removes the dangerous pattern.

- **Inline suppressions forbidden**: no `forge-lint: disable-next-line(…)`, `forge-lint: disable-line(…)`, `forge-lint: disable(…)`, or any other inline hint.
- **Project-level suppressions forbidden**: no `[lint] exclude_lints`, no `[lint] severity`, no `[lint] lint_on_build = false`, no other `foundry.toml` flag that silences a lint.
- **Selective-run workarounds forbidden**: do not invoke `forge lint --only-lint …`, `forge lint --severity …`, or any flag that skips the default lint set as a workaround for a specific finding.

Real code fixes for common findings:
- `unsafe-typecast` (warning) → use `SafeCast.toUintXX` / `SafeCast.toIntXX` from OpenZeppelin, or narrow the source type, or add an explicit `require(x <= type(uintXX).max)` guard before the cast — never the disable-hint.
- `unsafe-cheatcode` on `vm.readFile` / `vm.writeFile` / `vm.ffi` → **always forbidden in project code**. See "Script file I/O" below.
- `unsafe-cheatcode` on any other cheatcode → prefer restructuring (`vm.envAddress` / `vm.envUint` are safe alternatives for operator-supplied data).

"Fix warnings" requests from the user are NOT blanket authorization to suppress. They are requests for compliant code. If you cannot find a real code fix for a warning, **stop and ask the user** — do not reach for suppression.

Also prohibited with the same framing:
- `--ir-minimum` to work around stack-too-deep or via_ir issues. Fix stack depth at the source (scoped blocks, helper extraction) instead.
- Blanket compiler-warning ignores (`--ignored-error-codes …` used as a silencer rather than a scoped opt-out for vetted library paths).

### Script file I/O

**Scripts MUST NOT call `vm.readFile`, `vm.writeFile`, or `vm.ffi` directly** — forge-lint flags these as `unsafe-cheatcode` and there is no legitimate use in a project that has migrated to `forge-std/Config`.

**For reading configuration**: inherit the project's `DeploymentConfig` helper (in `script/lib/DeploymentConfig.sol`), which wraps two `forge-std/StdConfig` instances — one for inputs (`config/{network}/defaults.toml`), one for outputs (`deployments/{network}/addresses.toml`). Read via `defaults.get("key")` / the typed getters (`getMarginConfig()`, `getPairs()`) / `getAddress("oracle_module")`. `StdConfig` encapsulates the file read inside `lib/forge-std/` which forge-lint does not scan.

**For writing deployment artifacts**: use the Foundry-standard serialization cheatcodes (`vm.serializeUint`, `vm.serializeAddress`, `vm.serializeBytes32`, `vm.writeJson`) — these are NOT flagged. For writing addresses back to the Config-compatible TOML, use `addresses.set(chainId, key, value)` which persists via `vm.writeToml` under the hood.

**For operator-supplied data** (private keys, CLI flags, one-off per-invocation values): use `vm.envUint`, `vm.envAddress`, `vm.envString`, `vm.envOr` — NOT flagged.

**For build-time format conversions** (TOML → JSON, etc.): if the conversion cannot run inside `Deploy.s.sol` (because it's needed outside the deploy flow), use a Node or shell script invoked from the Makefile. NEVER write a Solidity helper that reads one file and writes another.

**`forge-std/Config` is the ONLY acceptable mechanism for reading configuration in project code.** Do not write custom TOML/JSON readers that wrap `vm.readFile`. Do not introduce a new `script/lib/*.sol` that reads a file — migrate the data to the Config-compatible TOML instead.

`unsafe-typecast` is a **warning**, not a note — it always requires a real fix (SafeCast or explicit bounds check). The ban above applies specifically to file-I/O cheatcodes.

## Code
- require() should always use custom errors.
- Do not use the if-then-revert pattern, always do a require() pattern.
- Never implement a looped array item removal since the array can grow indefinitely, always do a map removal for O(1).

## Best Practices
- Never have a separate internal functions section - leave internal function implementation at the nearest locality where it is used.
