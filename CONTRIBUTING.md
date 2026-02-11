# Contributing to make-completion-enhanced

Thank you for your interest in contributing to make-completion-enhanced! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Accept responsibility for mistakes
- Prioritize the community's best interests

## Getting Started

### Prerequisites

- Bash 4.0+ or Zsh 5.0+
- GNU Make
- AWK (GNU awk or compatible)
- Git
- Basic knowledge of shell scripting

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/make-completion-enhanced.git
   cd make-completion-enhanced
   ```

3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/original-owner/make-completion-enhanced.git
   ```

## Development Setup

### 1. Source the Completion Scripts

For testing during development:

```bash
# Bash
source make-completion-enhanced.bash

# Zsh
source _make-completion-enhanced
```

### 2. Test with Example Makefile

The repository includes a sample Makefile you can use for testing:

```bash
make <TAB>
make run app=<TAB>
```

### 3. Clear Cache When Testing

```bash
rm ~/.cache/make-completion-enhanced.cache
```

## How to Contribute

### Reporting Bugs

Before creating a bug report:
- Check existing issues to avoid duplicates
- Verify the bug exists in the latest version
- Collect relevant information (shell version, OS, etc.)

Create an issue with:
- Clear, descriptive title
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Minimal Makefile example if applicable

Example:
```markdown
**Description:** Completion fails with special characters in parameter values

**To Reproduce:**
1. Create Makefile with: ## PARAM name: value-with-dash
2. Type: make target name=<TAB>
3. No completions appear

**Expected:** Should show "value-with-dash"

**Environment:**
- OS: Ubuntu 22.04
- Shell: Bash 5.1.16
- Make version: GNU Make 4.3
```

### Suggesting Features

Feature requests should include:
- Clear description of the feature
- Use cases and examples
- Why this would be valuable
- Proposed implementation (if you have ideas)

### Pull Requests

We welcome pull requests for:
- Bug fixes
- New features
- Documentation improvements
- Performance enhancements
- Test coverage

## Coding Standards

### Shell Script Style

Follow these conventions for Bash and Zsh scripts:

#### 1. Indentation
- Use 2 spaces for indentation
- No tabs

```bash
# Good
_make_completion_enhanced() {
  local cur target
  cur="${COMP_WORDS[COMP_CWORD]}"
}

# Bad
_make_completion_enhanced() {
    local cur target
    cur="${COMP_WORDS[COMP_CWORD]}"
}
```

#### 2. Naming Conventions
- Function names: `snake_case` with `_` prefix for private functions
- Variables: `snake_case` for local, `UPPER_CASE` for globals
- Use descriptive names

```bash
# Good
local current_word target_name cache_file
CACHE_DIR="$HOME/.cache"

# Bad
local cw t cf
cache_dir="$HOME/.cache"
```

#### 3. Quoting
- Always quote variable expansions
- Use double quotes unless you need literal strings

```bash
# Good
local cur="${COMP_WORDS[COMP_CWORD]}"
if [[ "$cur" == "value" ]]; then

# Bad
local cur=${COMP_WORDS[COMP_CWORD]}
if [[ $cur == "value" ]]; then
```

#### 4. Conditionals
- Use `[[ ]]` for tests in Bash
- Use proper test operators

```bash
# Good
if [[ -f "$cache" && "$file" -nt "$cache" ]]; then

# Bad
if [ -f $cache ] && [ $file -nt $cache ]; then
```

#### 5. Error Handling
- Check for errors and handle them gracefully
- Use meaningful error messages

```bash
# Good
if [[ ! -f "$cache" ]]; then
  echo "Error: Cache file not found" >&2
  return 1
fi

# Bad
[[ ! -f "$cache" ]] && return 1
```

### AWK Scripts

#### 1. Formatting
- Use proper indentation
- Add comments for complex logic

```awk
# Good
awk '
BEGIN { tgt="__global__" }
/^## TARGET / {
  tgt=$3
}
/^## PARAM / {
  name=$3
  sub(":", "", name)
  vals=""
  for (i=4; i<=NF; i++) {
    if ($i !~ /TYPE=|REQUIRED|DEFAULT=/) {
      vals = vals " " $i
    }
  }
  print name "|" tgt "|" vals
}' Makefile
```

#### 2. Efficiency
- Minimize regex operations
- Use built-in functions when possible
- Avoid unnecessary variable assignments

### Documentation

#### 1. Code Comments
- Comment complex logic
- Explain why, not what
- Keep comments up to date

```bash
# Good
# Cache is invalidated when Makefile is newer than cache file
if [[ ! -f "$cache" || Makefile -nt "$cache" ]]; then

# Bad
# Check if cache exists
if [[ ! -f "$cache" ]]; then
```

#### 2. Function Documentation
- Document function purpose
- List parameters and return values
- Include usage examples

```bash
# Parses Makefile annotations and generates completion cache
#
# Arguments:
#   $1 - Path to Makefile
#   $2 - Output cache file
#
# Returns:
#   0 on success, 1 on error
#
# Example:
#   _parse_makefile "Makefile" "$cache_file"
_parse_makefile() {
  # implementation
}
```

## Testing

### Manual Testing

1. Create a test Makefile:
```makefile
## PARAM env: dev stage prod
## TARGET test
## PARAM mode: fast slow

test:
	@echo "Testing in $(env) with $(mode) mode"
```

2. Source the completion script:
```bash
source make-completion-enhanced.bash
```

3. Test completions:
```bash
make <TAB>          # Should show: test
make test <TAB>     # Should show: env=... mode=...
make test env=<TAB> # Should show: dev stage prod
```

### Test Cases to Cover

When making changes, test these scenarios:

1. **Basic Completion**
   - Target name completion
   - Global parameter completion
   - Target-specific parameter completion

2. **Edge Cases**
   - Empty Makefile
   - Makefile without annotations
   - Parameters with special characters
   - Multiple targets with same parameters

3. **Cache Behavior**
   - Cache creation on first use
   - Cache invalidation when Makefile changes
   - Cache reuse when Makefile unchanged

4. **Shell Compatibility**
   - Bash 4.x and 5.x
   - Zsh 5.x+
   - Different OS (Linux, macOS)

### Regression Testing

Before submitting:
```bash
# Test both shells
bash -c "source make-completion-enhanced.bash && make <TAB>"
zsh -c "source _make-completion-enhanced && make <TAB>"

# Test cache behavior
rm ~/.cache/make-completion-enhanced.cache
make <TAB>  # Should create cache
ls -la ~/.cache/make-completion-enhanced.cache  # Verify cache created
```

## Submitting Changes

### 1. Create a Branch

```bash
git checkout -b feature/my-feature
# or
git checkout -b fix/bug-description
```

### 2. Make Changes

- Write clean, well-documented code
- Follow coding standards
- Add tests if applicable
- Update documentation

### 3. Commit Changes

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add support for multi-line parameter values"
git commit -m "Fix cache invalidation on Makefile modification"
git commit -m "Update documentation with Zsh examples"

# Bad
git commit -m "fix bug"
git commit -m "updates"
git commit -m "WIP"
```

Commit message format:
```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat: Add support for conditional parameter suggestions

Implements the CMD annotation to allow parameters to suggest
different values based on the value of other parameters.

Closes #123
```

### 4. Push Changes

```bash
git push origin feature/my-feature
```

### 5. Create Pull Request

- Go to GitHub and create a pull request
- Fill out the PR template
- Link related issues
- Request review

PR should include:
- Clear description of changes
- Motivation and context
- How to test the changes
- Screenshots (if UI-related)
- Checklist of completed items

Example PR description:
```markdown
## Description
Adds support for multi-line parameter values in Makefile annotations.

## Motivation
Users want to define parameters with values that contain spaces or
special characters.

## Changes
- Modified AWK parser to handle quoted values
- Updated completion scripts to properly escape values
- Added tests for edge cases
- Updated documentation with examples

## Testing
- Tested with Bash 5.1 and Zsh 5.8
- Verified cache invalidation works correctly
- Tested with special characters: spaces, quotes, dashes

## Checklist
- [x] Code follows style guidelines
- [x] Documentation updated
- [x] Manual testing completed
- [x] Backwards compatible
```

### 6. Code Review Process

- Respond to feedback promptly
- Make requested changes
- Push updates to the same branch
- Engage in constructive discussion

### 7. After Merge

- Delete your feature branch
- Pull latest changes from upstream
- Update your fork

```bash
git checkout main
git pull upstream main
git push origin main
git branch -d feature/my-feature
```

## Development Workflow

### Typical Development Cycle

1. Sync with upstream
   ```bash
   git checkout main
   git pull upstream main
   ```

2. Create feature branch
   ```bash
   git checkout -b feature/new-feature
   ```

3. Make changes and test
   ```bash
   # Edit files
   source make-completion-enhanced.bash
   # Test completions
   ```

4. Commit with clear messages
   ```bash
   git add .
   git commit -m "feat: Add new feature"
   ```

5. Push and create PR
   ```bash
   git push origin feature/new-feature
   ```

## Getting Help

- Open an issue for questions
- Join discussions in existing issues
- Check documentation in README.md
- Review existing code for examples

## Recognition

Contributors will be:
- Listed in the AUTHORS file
- Mentioned in release notes
- Credited in documentation

Thank you for contributing to make-completion-enhanced!
