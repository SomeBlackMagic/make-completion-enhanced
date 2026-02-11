# API Documentation

This document describes the internal architecture and API of make-completion-enhanced.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Annotation Syntax](#annotation-syntax)
- [Parsing Logic](#parsing-logic)
- [Completion Flow](#completion-flow)
- [Cache Format](#cache-format)
- [Extending the System](#extending-the-system)

## Architecture Overview

```
┌─────────────────┐
│   Makefile      │
│  (Annotations)  │
└────────┬────────┘
         │
         │ Parse on first use or
         │ when Makefile changes
         ▼
    ┌────────────┐
    │ AWK Parser │
    └─────┬──────┘
          │
          │ Generate
          ▼
┌──────────────────┐
│  Cache File      │
│ (name|target|    │
│      values)     │
└────────┬─────────┘
         │
         │ Read during
         │ completion
         ▼
┌──────────────────┐
│ Completion       │
│ Function         │
│ (Bash/Zsh)       │
└────────┬─────────┘
         │
         │ Generate
         ▼
┌──────────────────┐
│  COMPREPLY       │
│  (Suggestions)   │
└──────────────────┘
```

## Annotation Syntax

### PARAM Annotation

Defines a parameter with possible values:

```makefile
## PARAM <name>: <value1> <value2> ... <valueN>
## PARAM <name> TYPE=<type> [REQUIRED] [DEFAULT=<value>]
```

#### Components

| Component | Required | Description | Example |
|-----------|----------|-------------|---------|
| `name` | Yes | Parameter name | `env`, `debug`, `region` |
| `:` | Yes (1st line) | Separator between name and values | `:` |
| `values` | Yes (1st line) | Space-separated possible values | `dev stage prod` |
| `TYPE=<type>` | No | Parameter type | `TYPE=enum`, `TYPE=bool` |
| `REQUIRED` | No | Mark parameter as required | `REQUIRED` |
| `DEFAULT=<value>` | No | Default value | `DEFAULT=False` |

#### Examples

```makefile
# Minimal
## PARAM env: dev prod

# With type
## PARAM env: dev stage prod
## PARAM env TYPE=enum

# Required parameter
## PARAM env: dev stage prod
## PARAM env TYPE=enum REQUIRED

# With default
## PARAM debug: True False
## PARAM debug TYPE=bool DEFAULT=False

# Multiple values
## PARAM region: us-east-1 us-west-2 eu-west-1 ap-southeast-1
```

### TARGET Annotation

Defines the scope for subsequent PARAM annotations:

```makefile
## TARGET <target-name>
## PARAM <param>: <values>
```

#### Scoping Rules

1. Parameters before any `TARGET` annotation are **global**
2. Parameters after a `TARGET` annotation apply only to that target
3. A new `TARGET` annotation starts a new scope

```makefile
## Global parameters
## PARAM env: dev prod

## TARGET deploy
## PARAM region: us-east-1 eu-west-1
# region is only available for 'make deploy'

## TARGET test
## PARAM coverage: True False
# coverage is only available for 'make test'
```

## Parsing Logic

### AWK Script Breakdown

The core parsing logic in both Bash and Zsh versions:

```awk
BEGIN {
  tgt="__global__"  # Start with global scope
}

/^## TARGET / {
  tgt=$3  # Switch to target-specific scope
}

/^## PARAM / {
  name=$3
  sub(":", "", name)  # Remove trailing colon

  vals=""
  # Collect values, skipping modifiers
  for (i=4; i<=NF; i++) {
    if ($i !~ /TYPE=|REQUIRED|DEFAULT=/) {
      vals = vals " " $i
    }
  }

  # Output: name|target|values
  print name "|" tgt "|" vals
}
```

### Parsing Steps

1. **Initialization**: Set scope to `__global__`
2. **Process Each Line**:
   - If line matches `## TARGET <name>`: Update scope to target name
   - If line matches `## PARAM <spec>`: Extract parameter info
3. **Parameter Extraction**:
   - Extract parameter name (field 3)
   - Remove trailing colon from name
   - Collect values (fields 4+) excluding TYPE/REQUIRED/DEFAULT
4. **Output**: Write `name|target|values` to cache

### Example

Input Makefile:
```makefile
## PARAM env: dev prod
## TARGET deploy
## PARAM region: us-east-1 eu-west-1
```

Output Cache:
```
env|__global__|dev prod
region|deploy|us-east-1 eu-west-1
```

## Completion Flow

### Bash Completion Flow

```bash
_make_completion_enhanced() {
  # 1. Get current word and target
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local target="${COMP_WORDS[1]}"

  # 2. Check cache validity
  if [[ ! -f "$cache" || Makefile -nt "$cache" ]]; then
    # Regenerate cache
    awk '...' Makefile > "$cache"
  fi

  # 3. Complete target name (position 1)
  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$(awk -F: '/^[a-zA-Z0-9_.-]+:/{print $1}' Makefile)" -- "$cur") )
    return
  fi

  # 4. Complete parameters (position 2+)
  COMPREPLY=( $(awk -F'|' -v t="$target" '
    ($2=="__global__"||$2==t) {
      split($3,v," ")
      for(i in v) print $1"="v[i]
    }
  ' "$cache" | compgen -W "$(cat)" -- "$cur") )
}
```

### Zsh Completion Flow

```zsh
_make() {
  # 1. Get target and cache location
  local target="${words[2]}"
  local cache="$HOME/.cache/make-completion-enhanced.cache"

  # 2. Check cache validity
  if [[ ! -f "$cache" || Makefile -nt "$cache" ]]; then
    # Regenerate cache
    awk '...' Makefile > "$cache"
  fi

  # 3. Complete target (position 2)
  if (( CURRENT == 2 )); then
    _describe targets "${(@f)$(awk -F: '/^[a-zA-Z0-9_.-]+:/{print $1}' Makefile)}"
  else
    # 4. Complete parameters (position 3+)
    _describe params "${(@f)$(awk -F'|' -v t="$target" '
      ($2=="__global__"||$2==t) {
        split($3,v," ")
        for(i in v) print $1"="v[i]
      }
    ' "$cache")}"
  fi
}
```

### Step-by-Step Example

User types: `make deploy region=<TAB>`

1. **Word Detection**:
   - `cur` = "region="
   - `target` = "deploy"
   - `COMP_CWORD` = 2

2. **Cache Check**:
   - Check if `~/.cache/make-completion-enhanced.cache` exists
   - Check if Makefile is newer than cache
   - Regenerate if needed

3. **Scope Resolution**:
   - Read cache file
   - Filter lines where target is "deploy" or "__global__"

4. **Value Extraction**:
   - Find parameter "region"
   - Extract values: "us-east-1 eu-west-1"
   - Format as: "region=us-east-1 region=eu-west-1"

5. **Filtering**:
   - Use `compgen` to filter matches starting with "region="
   - Return matches to shell

6. **Display**:
   - Shell shows: `us-east-1 eu-west-1`

## Cache Format

### File Location

```
$HOME/.cache/make-completion-enhanced.cache
```

### Format Specification

Each line in the cache:
```
<parameter_name>|<target_name>|<value1> <value2> ... <valueN>
```

### Field Descriptions

| Field | Description | Example |
|-------|-------------|---------|
| Parameter name | Name of the parameter without colon | `env`, `debug`, `region` |
| Target name | Target scope or `__global__` | `deploy`, `__global__` |
| Values | Space-separated possible values | `dev stage prod` |

### Example Cache

```
env|__global__|dev stage prod
debug|__global__|True False
verbose|__global__|True False
app|run|api worker scheduler
region|deploy|us-east-1 us-west-2 eu-west-1
replicas|deploy|1 2 3 5
```

### Cache Invalidation

Cache is regenerated when:
1. Cache file doesn't exist
2. Makefile modification time is newer than cache

```bash
if [[ ! -f "$cache" || Makefile -nt "$cache" ]]; then
  # Regenerate
fi
```

## Extending the System

### Adding New Parameter Types

To add a new parameter type (e.g., `TYPE=number`):

1. **Update AWK Parser**:
```awk
/^## PARAM / {
  # Existing logic...

  # Add type handling
  type=""
  for (i=4; i<=NF; i++) {
    if ($i ~ /TYPE=number/) {
      type="number"
    }
  }

  # Store type in cache if needed
}
```

2. **Update Completion Logic**:
```bash
# In completion function
if [[ $type == "number" ]]; then
  # Generate numeric completions
  COMPREPLY=( $(seq 1 10) )
fi
```

### Adding Dynamic Value Generation

To support dynamic values (e.g., from files, commands):

1. **Extend Annotation Syntax**:
```makefile
## PARAM branch SOURCE=git_branches
## PARAM file SOURCE=ls_files
```

2. **Add Source Resolution**:
```bash
case "$source" in
  git_branches)
    values=$(git branch --format='%(refname:short)')
    ;;
  ls_files)
    values=$(ls -1)
    ;;
esac
```

### Supporting Nested Parameters

For hierarchical parameters:

```makefile
## PARAM service: api frontend
## PARAM service.api.env: dev prod
## PARAM service.frontend.env: staging prod
```

Update parser to handle dot notation and conditional scoping.

### Custom Validators

Add validation hooks:

```makefile
## PARAM port TYPE=number VALIDATE=port_range
```

Implement validator:
```bash
validate_port_range() {
  local value=$1
  [[ $value -ge 1024 && $value -le 65535 ]]
}
```

### Multi-Value Parameters

Support multiple values for a single parameter:

```makefile
## PARAM tags MULTI
```

Update completion to allow multiple selections:
```bash
if [[ $multi == "true" ]]; then
  # Don't complete if already selected
  # Allow space-separated values
fi
```

## Internal Functions Reference

### Bash Functions

#### `_make_completion_enhanced()`

Main completion function registered with `complete`.

**Variables**:
- `cur`: Current word being completed
- `target`: The make target (first argument)
- `cache`: Path to cache file

**Returns**: Sets `COMPREPLY` array

### Zsh Functions

#### `_make()`

Main completion function registered with `compdef`.

**Variables**:
- `words`: Array of words in current command line
- `CURRENT`: Index of current word
- `target`: The make target

**Returns**: Calls `_describe` to set completions

### AWK Variables

Used in the parsing script:

| Variable | Type | Description |
|----------|------|-------------|
| `tgt` | String | Current target scope |
| `name` | String | Parameter name |
| `vals` | String | Space-separated values |
| `NF` | Number | Number of fields in line |
| `$1, $2, ...` | String | Field values |

## Performance Considerations

### Cache Efficiency

- Cache is read once per completion invocation
- Avoids re-parsing Makefile for every completion
- Typical cache size: < 1 KB
- Read time: < 1ms

### Parsing Performance

- AWK parsing: O(n) where n is number of lines
- Typical Makefile: < 1000 lines
- Parse time: < 10ms

### Optimization Tips

1. **Minimize Makefile Size**: Keep annotations concise
2. **Limit Value Count**: < 100 values per parameter
3. **Cache Location**: Use fast filesystem (SSD)
4. **Avoid Redundancy**: Don't duplicate global parameters

## Debugging

### Enable Debug Mode

```bash
# Bash
set -x
_make_completion_enhanced
set +x

# Zsh
setopt xtrace
_make
unsetopt xtrace
```

### Inspect Cache

```bash
cat ~/.cache/make-completion-enhanced.cache
```

### Test Parser Directly

```bash
awk '
BEGIN { tgt="__global__" }
/^## TARGET / { tgt=$3 }
/^## PARAM / {
  name=$3; sub(":", "", name)
  vals=""
  for (i=4;i<=NF;i++) if ($i !~ /TYPE=|REQUIRED|DEFAULT=/) vals=vals" "$i
  print name"|"tgt"|"vals
}' Makefile
```

### Verify Completion Registration

```bash
# Bash
complete -p make

# Zsh
whence -v _make
```

## Version Compatibility

### Bash Versions

- **4.0+**: Full support
- **3.x**: Limited support (no associative arrays if extended)

### Zsh Versions

- **5.0+**: Full support
- **4.x**: May work with limited features

### AWK Implementations

- **GNU AWK (gawk)**: Full support
- **mawk**: Full support
- **BSD awk**: Full support
- **busybox awk**: Basic support

## Future Enhancements

Planned features:

1. **Conditional Completions**: Values based on other parameters
2. **Dynamic Values**: From command output or files
3. **Validation**: Pre-completion value validation
4. **Description Support**: Help text for parameters
5. **Aliases**: Alternative names for parameters
6. **Deprecation Warnings**: Mark old parameters

## References

- [Bash Programmable Completion](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html)
- [Zsh Completion System](http://zsh.sourceforge.net/Doc/Release/Completion-System.html)
- [AWK Programming Language](https://www.gnu.org/software/gawk/manual/)
- [GNU Make Manual](https://www.gnu.org/software/make/manual/)
