# Solidity Standards

## Build
- For foundry-based projects, always attempt to fix warnings and notes after `forge build`.
- When fixing warnings, never add a lint suppress hint without asking for permissions.
- When fixing warnings, always remove unused things instead of simply commmenting out.
- Never add disable-next-line lint-disable without user approval.

## Code
- require() should always use custom errors.
- Do not use the if-then-revert pattern, always do a require() pattern.
- Never implement a looped array item removal since the array can grow indefinitely, always do a map removal for O(1).

## Best Practices
- Never have a separate internal functions section - leave internal function implementation at the nearest locality where it is used.
