# Agent Instructions for tmux-tokyo-night

This document provides comprehensive guidelines for AI coding agents working on the tmux-tokyo-night codebase.

## Project Overview

**Type:** Tmux status bar theme plugin written in pure Bash
**Language:** Bash shell scripting (requires bash, not sh)
**Architecture:** Modular plugin system with 15+ status bar widgets
**Version:** v1.11.0+ (uses semantic versioning)

## Build, Test, and Lint Commands

### Linting

```bash
# Run ShellCheck on all shell scripts (CI configuration)
shellcheck src/**/*.sh src/*.sh tmux-tokyo-night.tmux

# Run ShellCheck together (recommended for cross-file analysis)
shellcheck --check-sourced src/**/*.sh src/*.sh tmux-tokyo-night.tmux
```

### Testing

**No automated test suite exists.** Testing is performed manually:

1. Reload tmux configuration: `tmux source-file ~/.tmux.conf`
2. Test specific plugin: `bash src/plugin/<plugin_name>.sh`
3. Verify theme rendering in tmux status bar
4. Check cache behavior: `ls -lh ~/.cache/tmux-tokyo-night/`

### Running Single Plugin

```bash
# Execute plugin directly (sources dependencies automatically)
bash src/plugin/git.sh
bash src/plugin/kubernetes.sh

# Test with tmux environment
tmux run-shell "bash /path/to/src/plugin/git.sh"
```

### Release Process

- Uses semantic-release (automated via GitHub Actions)
- Conventional Commits format required
- Releases trigger on push to `main` branch
- CHANGELOG.md auto-generated

## Code Style Guidelines

### File Structure

**All Bash files must include:**

```bash
#!/usr/bin/env bash
# =============================================================================
# Plugin: <name> (or Utility Functions, Cache System, etc.)
# Description: <brief description>
# Dependencies: <list external commands required>
# =============================================================================
```

**Standard plugin structure:**

1. Shebang and header comment block
2. Directory detection: `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
3. Source dependencies with shellcheck directives
4. Configuration section with exported variables
5. Helper functions section
6. Main plugin logic
7. Direct execution guard: `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then`

### Imports and Dependencies

**Source files with shellcheck directive:**

```bash
# shellcheck source=src/utils.sh
. "$ROOT_DIR/../utils.sh"

# shellcheck source=src/cache.sh
. "$ROOT_DIR/../cache.sh"
```

**Plugin sourcing pattern:**

```bash
# In plugin files (src/plugin/*)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$ROOT_DIR/../utils.sh"
. "$ROOT_DIR/../cache.sh"
```

### Shell Script Requirements

**Always use strict error handling:**

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined variable, pipe failure
export LC_ALL=en_US.UTF-8  # Consistent locale
```

**Never use `sh` - always require bash:**

- Use bash arrays, associative arrays
- Use `[[` instead of `[` for tests
- Use bash string manipulation features

### Variable Naming

**Conventions:**

- `snake_case` for local variables and functions
- `UPPERCASE` for exported constants: `CACHE_DIR`, `PALETTE`, `ROOT_DIR`
- Plugin configuration pattern: `plugin_<name>_<property>`
  - Examples: `plugin_git_icon`, `plugin_kubernetes_accent_color`
- Prefix private variables with underscore: `_CACHE_IS_MACOS`

**Always declare scope:**

```bash
local var_name="value"    # Function-local
export GLOBAL_VAR="value" # Global exported

# Plugin config exports
export plugin_git_icon plugin_git_accent_color
```

### Function Style

**Documentation:**

```bash
# -----------------------------------------------------------------------------
# Brief one-line description
#
# Arguments:
#   $1 - Parameter name and description
#   $2 - Parameter name and description
#
# Output:
#   What the function outputs to stdout
#
# Returns:
#   Exit code meanings (0 for success, 1 for failure)
# -----------------------------------------------------------------------------
function_name() {
    local param1="$1"
    local param2="$2"
    # Implementation
}
```

**Function naming:**

- Descriptive verb-based names: `get_git_info`, `cache_is_valid`
- OS-specific suffixes when needed: `get_cpu_linux`, `get_cpu_darwin`
- No camelCase - use snake_case

### Error Handling

**Defensive patterns:**

```bash
# Check existence before operations
[[ -f "$file" ]] || return
[[ -d "$directory" ]] || return
[[ -z "$variable" ]] && return

# Redirect errors to /dev/null when checking availability
git rev-parse --git-dir &>/dev/null || return
command -v docker &>/dev/null || return

# Change directory safely
cd "$pane_path" 2>/dev/null || return
```

**Exit code handling:**

```bash
# Always return 0 for conditional plugins (they may not apply)
load_plugin() {
    get_git_info  # May output nothing if not in git repo
    return 0      # Always success
}
```

### ShellCheck Compliance

**Required practices:**

1. Quote all variable expansions: `"$var"` not `$var`
2. Use `[[` for tests, not `[`
3. Add shellcheck directives for sourced files
4. Disable warnings only when necessary with explanation:
   ```bash
   # shellcheck disable=SC2034  # Variable used in sourcing file
   plugin_git_icon=$(get_tmux_option "@theme_plugin_git_icon" " ")
   ```
5. Use command substitution with `$(...)` not backticks
6. Check command existence: `command -v foo &>/dev/null`

### Configuration Patterns

**Reading tmux options:**

```bash
# Use helper function with default fallback
icon=$(get_tmux_option "@theme_plugin_git_icon" " ")
color=$(get_tmux_option "@theme_plugin_git_accent_color" "blue7")
enabled=$(get_tmux_option "@theme_plugin_git_enabled" "true")

# Boolean checks
if [[ "$enabled" == "true" ]]; then
    # Plugin logic
fi
```

**Plugin configuration variables:**

```bash
# Always export for theme.sh to access
plugin_<name>_icon=$(get_tmux_option "@theme_plugin_<name>_icon" "default")
plugin_<name>_accent_color=$(get_tmux_option "@theme_plugin_<name>_accent_color" "blue")
plugin_<name>_accent_color_icon=$(get_tmux_option "@theme_plugin_<name>_accent_color_icon" "blue")

export plugin_<name>_icon plugin_<name>_accent_color plugin_<name>_accent_color_icon
```

### Caching System

**Using cache in plugins:**

```bash
# Source cache module
# shellcheck source=src/cache.sh
. "$ROOT_DIR/../cache.sh"

# Standard cache pattern
load_plugin() {
    local ttl=60  # Cache TTL in seconds

    if cached_value=$(cache_get "plugin_name" "$ttl"); then
        echo -n "$cached_value"
    else
        new_value=$(fetch_expensive_data)
        cache_set "plugin_name" "$new_value"
        echo -n "$new_value"
    fi
}
```

**Cache guidelines:**

- Use caching for expensive operations (API calls, command execution)
- TTL: 60s for frequently changing data, 300s+ for stable data
- Cache location: `~/.cache/tmux-tokyo-night/`
- Always use `-n` with echo to avoid trailing newlines

### Output and Formatting

**Plugin output:**

```bash
# Use echo -n to avoid newlines
echo -n "$output"

# Use printf for precise control
printf '%s' "$output"

# Never use echo without -n for final output
```

**Tmux formatting:**

- Access colors via: `${PALETTE[color_name]}`
- Use tmux format strings: `#[fg=color,bg=color]`
- Check theme.sh for formatting examples

## Commit Message Format

**Use Conventional Commits:**

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature or plugin
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style/formatting (not visual style)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance tasks

**Breaking changes:**

- Use `feat!:` or `fix!:` for breaking changes
- Describe breaking change in commit body

**Examples:**

```
feat(plugin): add kubernetes context display
fix(git): handle detached HEAD state correctly
refactor(cache): simplify cache validation logic
docs(readme): update installation instructions
```

## Common Patterns and Idioms

### Getting tmux pane path

```bash
pane_path="$(tmux display-message -p '#{pane_current_path}')"
[[ -z "$pane_path" || ! -d "$pane_path" ]] && return
cd "$pane_path" 2>/dev/null || return
```

### Checking command availability

```bash
command -v docker &>/dev/null || return
```

### Parsing command output

```bash
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Process line
done <<< "$command_output"
```

### Platform detection

```bash
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS-specific
else
    # Linux-specific
fi
```

## File Organization

```
src/
├── cache.sh                # Caching utilities (175 lines)
├── utils.sh                # Common utilities (88 lines)
├── theme.sh                # Main theme loader
├── conditional_plugin.sh   # Conditional plugin wrapper
├── palette/               # Color scheme
│   └── storm.sh
└── plugin/                 # Plugin modules (15 total)
    ├── git.sh             # Example: ~82 lines
    ├── kubernetes.sh
    └── ...
```

**Adding new plugins:**

1. Create `src/plugin/new_plugin.sh` following structure above
2. Implement `load_plugin()` function
3. Export configuration variables
4. Update theme.sh to include new plugin
5. Document in README.md

## Important Notes for Agents

- **No TypeScript/JavaScript:** This is pure Bash - don't suggest npm commands
- **Manual testing required:** No automated test suite exists
- **ShellCheck is mandatory:** All code must pass ShellCheck
- **Cache for performance:** Use caching for any expensive operations
- **Conditional plugins:** Always return 0, even if plugin doesn't apply
- **Cross-platform:** Support both Linux and macOS (stat, BSD vs GNU tools)
- **Quote everything:** ShellCheck will catch unquoted expansions
- **Direct execution guard:** Allow plugins to be sourced or executed

## Resources

- ShellCheck: https://www.shellcheck.net/
- Tmux format strings: `man tmux` (FORMATS section)
- Project README: Comprehensive user documentation
- CHANGELOG.md: Auto-generated release notes
