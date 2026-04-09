# Home Manager Configuration

## NixOS MCP Server

This project has access to a NixOS MCP server. **Always use it** when working with Nix configuration instead of guessing at package names, option paths, or syntax.

### `mcp__nixos__nix` — Query Nix ecosystem documentation

Use this tool to look up packages, options, and documentation across the Nix ecosystem.

**Key parameters:**

- `action`: `search` | `info` | `stats` | `options` | `channels` | `flake-inputs` | `cache`
- `source`: `nixos` | `home-manager` | `darwin` | `flakes` | `flakehub` | `nixvim` | `wiki` | `nix-dev` | `noogle` | `nixhub`
- `type`: `packages` | `options` | `programs` | `list` | `ls` | `read`
- `channel`: `unstable` | `stable` | `25.05`
- `query`: search term, package name, or option path

**Common usage patterns:**

- **Find a package:** `action: "search", source: "nixos", type: "packages", query: "ripgrep"`
- **Get package info:** `action: "info", source: "nixos", type: "packages", query: "ripgrep"`
- **Look up a home-manager option:** `action: "search", source: "home-manager", type: "options", query: "programs.git"`
- **Get full option docs:** `action: "info", source: "home-manager", type: "options", query: "programs.git.enable"`
- **Search NixOS options:** `action: "search", source: "nixos", type: "options", query: "networking.firewall"`
- **Look up a Nix builtin/library function:** `action: "search", source: "noogle", query: "filterAttrs"`
- **Check flake inputs:** `action: "flake-inputs", type: "list", query: ""`

### `mcp__nixos__nix_versions` — Package version history

Use this to find which nixpkgs commits/channels carry a specific version of a package.

- `package`: package name (required)
- `version`: specific version to find (optional)
- `limit`: number of results, 1-50

### When to use

- Adding or configuring a new program: search home-manager options first, then nixos packages.
- Unsure about an option's type or default: use `info` to read the full option definition.
- Need a specific package version: use `mcp__nixos__nix_versions`.
- Writing Nix expressions: search `noogle` for library functions.
