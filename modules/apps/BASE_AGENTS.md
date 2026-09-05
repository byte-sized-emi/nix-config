## agent-browser — Browser Automation & Web (preferred for browsing/search)

Use agent-browser for fetching pages, searching the web, and interactive browsing. The browser persists via a daemon, so chain commands with &&. Prefer this over the searxng MCP.

Common usage:

```bash
agent-browser read https://example.com # agent-readable page text
agent-browser open example.com && agent-browser snapshot -i # navigate + interactive elements
agent-browser open https://duckduckgo.com/?q=nix+flake+blueprint && agent-browser read # search
agent-browser fill @e3 "text" && agent-browser click @e2 # interact via refs
agent-browser screenshot --full # full-page screenshot
agent-browser chat "open google.com and search for cats" # one-shot AI driving - currently not available
```

Load usage patterns with `agent-browser skills get core --full` before complex flows - be careful, this is a very large document.

## RTK

RTK is an agent-focused binary which makes common command outputs shorter. Use it before any `git`, `cargo`, `docker` , `nix`, `nixos-rebuild` or similar commands where you do not need the 100% exact output.

Usage examples:

```bash
rtk git status
rtk git log
rtk cargo check
rtk cargo test
rtk nixos-rebuild build
```

RTK can also be used for reading files, listing directories, grepping and diffing:

```bash
rtk ls .                        # Compact directory listing
rtk read file.rs                # Smart file reading
rtk read file.rs -l aggressive  # Signatures only (strips bodies)
rtk smart file.rs               # 2-line heuristic code summary
rtk find "*.rs" .               # Compact find results
rtk grep "pattern" .            # Grouped search results
rtk diff file1 file2            # Condensed diff (exit 1 if files differ)
```

Use `rtk grep` and `rtk find` whenever possible, these just wrap the shell commands for better output. Prefer built-in tools over the rtk command line equivalents. When reading a large source code file, try to use `rtk read` with the `aggressive` flag to get a condensed summary of, for example, function signatures. More documentation is available here: https://github.com/rtk-ai/rtk

## Downloading files

Some fetches can result in very large files, of which only a part is necessary for completion of the task. This is especially the case when downloading files or reading the file tree from a git provider like github. Only download the minimum required, for example a line and some context around it, for example by using curl like this: `curl -s https://raw.githubusercontent.com/...RepositoryApi.java | sed -n 5,10p` (returns only lines 5-10).
Be careful - always limit the amount of data downloaded, for example with `head`. You can always request more context, but only have a limited context window.
