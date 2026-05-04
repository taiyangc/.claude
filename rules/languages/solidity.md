# Solidity Standards

Universal Solidity / Foundry rules. Project-specific paths, CI step names,
and helper-contract names belong in the project's own Solidity rule file
(e.g. `.claude/rules/solidity-conventions.md`), not here.

## Formatting (mandatory)

- **Always run `forge fmt` immediately after any Solidity change** — source
  files, test files, scripts, interfaces, libraries. No exceptions.
- Run it BEFORE `forge build` / `forge test` / `forge coverage` so subsequent
  diffs are about logic, not whitespace. Mixed formatting + logic changes in
  the same commit are a review-readability regression.
- `forge fmt` with no args formats every `*.sol` under the foundry project
  root. Run it from wherever `foundry.toml` lives.
- Also run after reverts, merges, auto-generated binding regeneration, and
  any edit the linter may have nudged. Assume any hand edit has drifted from
  the formatter's output.
- If a pre-commit / pre-push hook already runs `forge fmt`, still run it
  manually after edits so your local state matches what the hook will produce
  — avoids noisy "re-format" commits after a hook rewrites your staged files.

## Build

- For foundry projects, always attempt to fix warnings AND informational
  `note[…]` findings after `forge build`. There is NO "legitimate patterns"
  carveout — every `note[unsafe-cheatcode]` must be removed by restructuring
  the code.
- When fixing warnings, always remove unused things instead of simply
  commenting out.
- `forge build` at HEAD must emit **zero** `note[unsafe-cheatcode]` findings.

### Never suppress forge-lint findings by any means

Every path below is forbidden. The acceptable response to a **warning** is
always a **real code change** that removes the dangerous pattern.

- **Inline suppressions forbidden**: no `forge-lint: disable-next-line(…)`,
  `forge-lint: disable-line(…)`, `forge-lint: disable(…)`, or any other
  inline hint.
- **Project-level suppressions forbidden**: no `[lint] exclude_lints`, no
  `[lint] severity`, no `[lint] lint_on_build = false`, no other
  `foundry.toml` flag that silences a lint.
- **Selective-run workarounds forbidden**: do not invoke
  `forge lint --only-lint …`, `forge lint --severity …`, or any flag that
  skips the default lint set as a workaround for a specific finding.

Real code fixes for common findings:
- `unsafe-typecast` (warning) → use `SafeCast.toUintXX` / `SafeCast.toIntXX`
  from OpenZeppelin, or narrow the source type, or add an explicit
  `require(x <= type(uintXX).max)` guard before the cast — never the
  disable-hint.
- `unsafe-cheatcode` on `vm.readFile` / `vm.writeFile` / `vm.ffi` → forbidden
  in project code; see "Script file I/O" below.
- `unsafe-cheatcode` on any other cheatcode → prefer restructuring
  (`vm.envAddress` / `vm.envUint` are safe alternatives for operator-supplied
  data).

"Fix warnings" requests from the user are NOT blanket authorization to
suppress. They are requests for compliant code. If you cannot find a real
code fix for a warning, **stop and ask the user** — do not reach for
suppression.

Also prohibited with the same framing:
- `--ir-minimum` to work around stack-too-deep or via_ir issues. Fix stack
  depth at the source (scoped blocks, helper extraction) instead.
- Blanket compiler-warning ignores (`--ignored-error-codes …` used as a
  silencer rather than a scoped opt-out for vetted library paths).

## Script file I/O

Scripts MUST NOT call `vm.readFile`, `vm.writeFile`, or `vm.ffi` directly
— forge-lint flags these as `unsafe-cheatcode` and there is no legitimate
use in modern foundry projects.

- **For reading configuration** → use `forge-std/StdConfig`. The file read
  is encapsulated inside `lib/forge-std/`, which forge-lint does not scan.
  Most projects wrap this in a domain-specific helper that exposes typed
  getters; check the project's own Solidity rule for the local helper.
- **For writing deployment artifacts** → use the Foundry-standard
  serialization cheatcodes (`vm.serializeUint`, `vm.serializeAddress`,
  `vm.serializeBytes32`, `vm.writeJson`) — these are NOT flagged.
  `StdConfig.set(chainId, key, value)` persists via `vm.writeToml` under
  the hood for TOML output.
- **For operator-supplied data** (private keys, CLI flags, one-off
  per-invocation values) → use `vm.envUint`, `vm.envAddress`, `vm.envString`,
  `vm.envOr` — NOT flagged.
- **For build-time format conversions** (TOML → JSON, etc.) — if the
  conversion cannot run inside the deploy script, use a Node or shell
  script invoked from the build system. NEVER write a Solidity helper
  that reads one file and writes another.

`unsafe-typecast` is a **warning**, not a note — it always requires a real
fix (SafeCast or explicit bounds check). The file-I/O ban above applies
specifically to file-I/O cheatcodes.

## Code

- `require()` should always use custom errors.
- Do not use the if-then-revert pattern, always do a `require()` pattern.
- Never implement a looped array item removal since the array can grow
  indefinitely, always do a map removal for O(1).

## No audit-finding ID tags in code

NEVER include audit-finding identifiers in any source file. This means
`H-1`, `M-3`, `L-7`, project-prefixed IDs (e.g. `<PROJECT>-XXX-NNN`),
`T<number>`, Codex / external-reviewer finding references, or any other
external-tracker reference — in **any** code file, including `@title` /
`@notice` / `@dev` NatSpec, inline comments, test function names, error
message strings, and variable names.

Audit IDs belong in `audits/`, `specs/`, `docs/`, PR descriptions, and
commit messages — NEVER in code. The IDs are anchored to a specific audit
document and become stale dead references the moment that audit cycle
ends. Future readers shouldn't need to fetch a 2,500-line audit PDF to
understand a comment.

The fix-rationale comment itself is welcome — just describe the *why*
without the ID. "Open-positions guard prevents stranded positions" yes;
"Open-positions guard (H-3)" no.

Each project's Solidity rule should specify the exact directories to sweep
and any project-prefixed ID format. Run that grep before declaring an
audit-fix branch ready.

## Modifier extraction (DRY duplicate requires)

When the same multi-line require pattern recurs across functions, extract
it into a named modifier — not just a single check, but the WHOLE logical
group of related checks that conceptually belong together at every call
site.

- Don't modifier-ize a single require line — that's indirection without DRY
  win. EITHER inline OR combine with related checks.
- Combine related guards (zero-address + code-length / ownership +
  open-status + state-enabled + not-matured) into ONE modifier per logical
  group, not one modifier per check.
- House cross-cutting modifiers used by 3+ contracts in a shared abstract
  base contract. Don't redefine the same modifier in each contract.
- Modifier order matters: state-of-protocol checks (slot-already-wired,
  mode-not-paused) come BEFORE input-validation modifiers (EOA / zero
  checks). UX rule: if the slot is locked, the meaningful revert is "you
  can't change this anyway", not "your input was bad".

**Reusable address-validation modifier pattern:**

```solidity
abstract contract AddressGuards {
    modifier onlyContractAddress(address addr) {
        require(addr != address(0), Errors.ZeroAddress());
        require(addr.code.length > 0, Errors.InvalidParameter());
        _;
    }
    modifier onlyContractAddressOrZero(address addr) {
        require(addr == address(0) || addr.code.length > 0, Errors.InvalidParameter());
        _;
    }
}
```

The EOA-rejection check (`code.length > 0`) is essential for any setter
that stores an address called as a contract. An EOA in such a slot causes
silent failure: void calls return success with empty data; typed-return
calls revert on decode. Both are surprising. The two-line modifier above
prevents the entire class.

## Best Practices

- Never have a separate internal-functions section — leave internal
  function implementation at the nearest locality where it is used.
