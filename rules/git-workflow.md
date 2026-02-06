# Git Workflow

## Commit Message Format
- Always write commit messages using Conventional Commits 1.0.0.
- Format: `<type>(<optional scope>): <short description>`
- If breaking: include `!` after type/scope OR a `BREAKING CHANGE:` footer.
- Keep subject ≤ 72 chars; use present tense.
- Reference: https://www.conventionalcommits.org/en/v1.0.0/

## Merge Conventions
- When merging upstream updates, always do a merge directly from upstream remote url and resolve conflicts. DO NOT create a new commit with changes from upstream without git history.
- When removing sensitive information, always make sure to rebase to the commit that introduced the sensitive information, then ask user to force push afterwards. DO NOT auto force push without user permission.

## Github
- When creating a project or linking issues to projects, always use the current repository's project context, unless specifically asked by user to use the organization's project context.
