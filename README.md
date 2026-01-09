# uithub-cli

CLI tool for fetching and caching GitHub repos as LLM-friendly Markdown.

Uses the [uithub.com](https://uithub.com) API to cache entire repositories as single Markdown files locally.

## Requirements

- [Idris2](https://github.com/idris-lang/Idris2) 0.8.0+
- [pack](https://github.com/stefan-hoeck/idris2-pack) (Idris2 package manager)
- uithub.com API key (get one at [https://uithub.com](https://uithub.com))

## Build & Install

```bash
# Clone
git clone https://github.com/shogochiai/uithub-cli.git
cd uithub-cli

# Build
pack build uithub-cli.ipkg

# Install to ~/.local/bin (assuming it's in your PATH)
cp build/exec/uithub-cli ~/.local/bin/
cp -r build/exec/uithub-cli_app ~/.local/bin/

# Verify
uithub-cli
```

## Setup

### API Key Configuration

```bash
# After obtaining API key from uithub.com
uithub-cli config set-key uitk_xxxxxxxxxxxxxxxx

# Verify
uithub-cli config show
```

## Usage

### Basic Commands

```bash
# Fetch and cache a repository
uithub-cli fetch owner/repo

# Get from cache (auto-fetches if not cached)
uithub-cli get owner/repo

# Force re-fetch
uithub-cli update owner/repo

# List cached repos
uithub-cli list
```

### Repository Management with uithub.toml

Manage repos of interest per-project or machine-wide using `uithub.toml`.

#### Project-local (./uithub.toml)

```bash
# Fetch and save to local uithub.toml
uithub-cli fetch -s owner/repo
uithub-cli fetch --save owner/repo

# List repos in local uithub.toml
uithub-cli repos

# Fetch all repos from local uithub.toml
uithub-cli install
```

#### Machine-global (~/.uithub-cli/uithub.toml)

```bash
# Fetch and save to global uithub.toml
uithub-cli fetch -g owner/repo
uithub-cli fetch --global owner/repo

# List repos in global uithub.toml
uithub-cli repos -g

# Fetch all repos from global uithub.toml
uithub-cli install -g
```

### uithub.toml Format

```toml
# uithub.toml - repos of interest

anthropics/claude-code
shogochiai/idris2-coverage
idris-lang/Idris2
```

## Example: Project Setup

When you want to reference dependency sources in a new project:

```bash
cd my-project

# Fetch related repos and record in uithub.toml
uithub-cli fetch -s idris-lang/Idris2
uithub-cli fetch -s stefan-hoeck/idris2-pack
uithub-cli fetch -s stefan-hoeck/idris2-elab-util

# Check uithub.toml
uithub-cli repos
# local uithub.toml:
#   idris-lang/Idris2
#   stefan-hoeck/idris2-pack
#   stefan-hoeck/idris2-elab-util

# Bulk fetch on another machine
uithub-cli install
```

## Example: Global Library

Register frequently referenced repos globally:

```bash
# Register globally
uithub-cli fetch -g anthropics/anthropic-cookbook
uithub-cli fetch -g anthropics/courses

# Access from anywhere
uithub-cli get anthropics/anthropic-cookbook | head -100
```

## Cache Location

- Config: `~/.uithub-cli/config`
- Cache: `~/.uithub-cli/cache/<owner>/<repo>/content.md`
- Global repo list: `~/.uithub-cli/uithub.toml`

## Notes

- Large repositories may timeout on uithub.com's side
- Private repositories return 404
- Cache persists until manually deleted

## License

MIT
