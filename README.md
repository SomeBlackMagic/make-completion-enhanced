# make-completion-enhanced

Enhanced Make completion with parameters and conditions for Bash and Zsh.

## Overview

`make-completion-enhanced` adds intelligent autocompletion to your Makefiles by parsing special comment annotations. It supports typed parameters, conditional suggestions, per-target parameters, and works with both Bash and Zsh shells.

## Features

- **Typed Parameters**: Support for `enum`, `bool`, and custom types
- **Global & Per-Target Parameters**: Define parameters globally or for specific targets
- **Conditional Suggestions**: Dynamic parameter suggestions based on context
- **Multi-Shell Support**: Works with both Bash and Zsh
- **Smart Caching**: Automatically caches and updates completions
- **DEB Packaging**: Easy installation via `.deb` package

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/yourusername/make-completion-enhanced.git
cd make-completion-enhanced

# For Bash
echo "source $(pwd)/make-completion-enhanced.bash" >> ~/.bashrc
source ~/.bashrc

# For Zsh
echo "source $(pwd)/_make-completion-enhanced" >> ~/.zshrc
source ~/.zshrc
```

### Using DEB Package

```bash
# Build the package
make deb

# Install
sudo dpkg -i ../make-completion-enhanced_*.deb
```

### Manual Installation

```bash
# Install system-wide
sudo make install

# Restart your shell or source the completion script
source /etc/bash_completion.d/make-completion-enhanced  # Bash
source /usr/share/zsh/site-functions/_make-completion-enhanced  # Zsh
```

## Usage

### Basic Syntax

Add special comments to your Makefile to define parameters:

```makefile
## PARAM <name>: <value1> <value2> ...
## PARAM <name> TYPE=<type> [REQUIRED] [DEFAULT=<value>]
## TARGET <target-name>
```

### Complete Example

```makefile
## PARAM env: dev stage prod
## PARAM env TYPE=enum REQUIRED

## PARAM debug: True False
## PARAM debug TYPE=bool DEFAULT=False

## PARAM verbose: True False
## PARAM verbose TYPE=bool DEFAULT=False

## TARGET run
## PARAM app: api worker scheduler
## PARAM app TYPE=enum REQUIRED

## TARGET deploy
## PARAM region: us-east-1 us-west-2 eu-west-1
## PARAM region TYPE=enum DEFAULT=us-east-1

run:
	@echo "Running app=$(app) env=$(env) debug=$(debug)"

deploy:
	@echo "Deploying to $(region) env=$(env)"

build:
	@echo "Building for env=$(env)"

test:
	@echo "Testing with verbose=$(verbose)"
```

### Interactive Completion Examples

```bash
# Tab completion for targets
make <TAB>
# Shows: run deploy build test

# Global parameters available for all targets
make build env=<TAB>
# Shows: dev stage prod

make build debug=<TAB>
# Shows: True False

# Target-specific parameters
make run <TAB>
# Shows: env=dev env=stage env=prod app=api app=worker app=scheduler debug=True debug=False

make run app=<TAB>
# Shows: api worker scheduler

make deploy region=<TAB>
# Shows: us-east-1 us-west-2 eu-west-1

# Combined usage
make run app=api env=dev debug=True
make deploy region=us-west-2 env=prod
```

## Parameter Syntax Reference

### Global Parameters

Global parameters are available for all targets:

```makefile
## PARAM <name>: <value1> <value2> <value3>
```

Example:
```makefile
## PARAM env: dev stage prod
```

### Per-Target Parameters

Define parameters specific to a target:

```makefile
## TARGET <target-name>
## PARAM <name>: <value1> <value2>
```

Example:
```makefile
## TARGET deploy
## PARAM region: us-east-1 us-west-2
```

### Parameter Types

#### Enum Type
```makefile
## PARAM env: dev stage prod
## PARAM env TYPE=enum REQUIRED
```

#### Bool Type
```makefile
## PARAM debug: True False
## PARAM debug TYPE=bool DEFAULT=False
```

### Modifiers

- **REQUIRED**: Parameter must be provided
- **DEFAULT=<value>**: Default value if not specified
- **TYPE=<type>**: Parameter type (enum, bool, etc.)

```makefile
## PARAM env TYPE=enum REQUIRED
## PARAM debug TYPE=bool DEFAULT=False
## PARAM level TYPE=enum DEFAULT=info
```

## Advanced Examples

### Microservices Deployment

```makefile
## PARAM env: development staging production
## PARAM env TYPE=enum REQUIRED

## TARGET deploy-api
## PARAM replicas: 1 2 3 5
## PARAM replicas TYPE=enum DEFAULT=2

## TARGET deploy-worker
## PARAM queue: high normal low
## PARAM queue TYPE=enum REQUIRED

deploy-api:
	@echo "Deploying API with $(replicas) replicas to $(env)"
	kubectl apply -f api-deployment.yaml

deploy-worker:
	@echo "Deploying worker for $(queue) queue to $(env)"
	kubectl apply -f worker-deployment.yaml
```

Usage:
```bash
make deploy-api env=production replicas=5
make deploy-worker env=staging queue=high
```

### CI/CD Pipeline

```makefile
## PARAM ci: True False
## PARAM ci TYPE=bool DEFAULT=False

## TARGET test
## PARAM coverage: True False
## PARAM coverage TYPE=bool DEFAULT=True

## TARGET build
## PARAM optimize: True False
## PARAM optimize TYPE=bool DEFAULT=True

test:
	@if [ "$(coverage)" = "True" ]; then \
		npm test -- --coverage; \
	else \
		npm test; \
	fi

build:
	@if [ "$(optimize)" = "True" ]; then \
		npm run build -- --optimization; \
	else \
		npm run build; \
	fi

ci: test build
	@echo "CI pipeline complete"
```

Usage:
```bash
make test coverage=True
make build optimize=False
make ci ci=True
```

### Docker Environment

```makefile
## PARAM env: local docker kubernetes
## PARAM env TYPE=enum DEFAULT=local

## TARGET up
## PARAM detach: True False
## PARAM detach TYPE=bool DEFAULT=False

## TARGET logs
## PARAM follow: True False
## PARAM follow TYPE=bool DEFAULT=True

up:
	@if [ "$(detach)" = "True" ]; then \
		docker-compose up -d; \
	else \
		docker-compose up; \
	fi

logs:
	@if [ "$(follow)" = "True" ]; then \
		docker-compose logs -f; \
	else \
		docker-compose logs; \
	fi

down:
	docker-compose down
```

Usage:
```bash
make up detach=True
make logs follow=False
make down
```

## How It Works

1. **Parsing**: The completion script uses `awk` to parse Makefile comments
2. **Caching**: Results are cached in `~/.cache/make-completion-enhanced.cache`
3. **Auto-Update**: Cache is regenerated when Makefile is modified
4. **Context-Aware**: Completions adapt based on the selected target

### Cache Location

```
~/.cache/make-completion-enhanced.cache
```

The cache is automatically updated when the Makefile is modified.

## Shell Support

### Bash

The Bash completion uses the `complete` command and `COMPREPLY` array:

```bash
complete -F _make_completion_enhanced make
```

### Zsh

The Zsh completion uses the `compdef` system:

```zsh
#compdef make
```

Both implementations share the same parsing logic and cache mechanism.

## Development

### Project Structure

```
make-completion-enhanced/
├── Makefile                      # Example Makefile with annotations
├── make-completion-enhanced.bash # Bash completion script
├── _make-completion-enhanced     # Zsh completion script
├── debian/                       # Debian packaging files
│   ├── control
│   ├── install
│   ├── changelog
│   └── rules
└── README.md                     # This file
```

### Building DEB Package

```bash
make deb
```

### Testing

Create a test Makefile and try the completions:

```bash
# Source the completion script
source make-completion-enhanced.bash

# Type and press TAB
make <TAB>
make run app=<TAB>
```

## Troubleshooting

### Completions Not Working

1. Ensure the script is sourced in your shell config:
   ```bash
   # Bash
   grep make-completion-enhanced ~/.bashrc

   # Zsh
   grep make-completion-enhanced ~/.zshrc
   ```

2. Verify the cache is being created:
   ```bash
   ls -la ~/.cache/make-completion-enhanced.cache
   ```

3. Check for syntax errors in your Makefile annotations:
   ```bash
   awk '/^## /{print}' Makefile
   ```

### Cache Not Updating

Delete the cache manually:
```bash
rm ~/.cache/make-completion-enhanced.cache
```

### Completions Show Wrong Values

Verify your Makefile syntax:
- Each `## PARAM` must be on its own line
- Target definitions must use `## TARGET <name>`
- Values should be space-separated

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Authors

- Original Author: [Your Name]
- Contributors: [List of contributors]

## Acknowledgments

- Inspired by the need for better Make completion
- Built with standard shell tools (awk, grep, etc.)
- Compatible with modern Bash and Zsh shells

## See Also

- [GNU Make Documentation](https://www.gnu.org/software/make/manual/)
- [Bash Completion Guide](https://github.com/scop/bash-completion)
- [Zsh Completion System](https://zsh.sourceforge.io/Doc/Release/Completion-System.html)
