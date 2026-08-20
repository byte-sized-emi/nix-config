# Rust-specific agent instructions

## Commands (run in `modules/packages/<name>/`)

| Command                      | Description        |
| ---------------------------- | ------------------ |
| `cargo check`                | Fast compile check |
| `cargo clippy --all-targets` | Lint all targets   |
| `cargo test`                 | Run all tests      |
| `cargo test <test_name>`     | Run a single test  |
| `cargo run`                  | Run binary         |
| `bacon`                      | Watch-mode check   |
| `bacon test`                 | Watch-mode testing |

### Rust

- **Edition**: 2024
- **Formatting**: `rustfmt` defaults
- **Naming**: `snake_case` functions/vars, `PascalCase` types
- **Errors**: Return `Result<T, String>` with descriptive messages
- **Imports**: std, then external crates, then local
- **Structs**: `#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]`
- **Tests**: `similar_asserts::assert_eq`, `Result<(), String>` return
