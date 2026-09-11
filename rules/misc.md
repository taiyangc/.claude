# Misc Guardrails

- Never read/write `.env` or `.env*` files without asking for explicit permissions.
  Exception: `.env*.example` template files hold placeholders, not secrets — read them freely.
  This is enforced in `~/.claude/settings.json` via `permissions.deny`, which blocks the file
  tools and named-file shell reads (`cat`, `head`, `tail`, `sed`). Indirect reads (`grep -r`,
  a script that opens the file itself) are NOT blocked — do not use them to work around the rule.
