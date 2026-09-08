# Rust Standards

- Never add allow(dead_code) to fix warnings! Either remove dead code or propose implementation.
- Always run `cargo fmt` after any Rust code changes (including auto-generated bindings) before committing, scoped with -p <crate> to the crates you changed when the checkout is shared with other agents.
- Use crates.io to suggest the latest Cargo dependency major/minor version updates.
