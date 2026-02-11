# Usage Guide

This guide provides detailed examples and use cases for `make-completion-enhanced`.

## Table of Contents

- [Quick Start](#quick-start)
- [Parameter Types](#parameter-types)
- [Real-World Examples](#real-world-examples)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)

## Quick Start

### Minimal Example

```makefile
## PARAM env: dev prod
run:
	@echo "Running in $(env) environment"
```

Usage:
```bash
make run env=<TAB>  # Completes: dev prod
make run env=dev    # Output: Running in dev environment
```

### With Target-Specific Parameters

```makefile
## TARGET deploy
## PARAM service: api frontend backend
deploy:
	@echo "Deploying $(service)"
```

Usage:
```bash
make deploy service=<TAB>  # Completes: api frontend backend
```

## Parameter Types

### Enum Type

Best for fixed set of choices:

```makefile
## PARAM log_level: debug info warning error
## PARAM log_level TYPE=enum DEFAULT=info

run:
	@echo "Log level: $(log_level)"
```

### Bool Type

For boolean flags:

```makefile
## PARAM dry_run: True False
## PARAM dry_run TYPE=bool DEFAULT=False

deploy:
	@if [ "$(dry_run)" = "True" ]; then \
		echo "DRY RUN: Would deploy..."; \
	else \
		echo "Deploying..."; \
	fi
```

### Required Parameters

Force users to provide values:

```makefile
## PARAM environment TYPE=enum REQUIRED
## PARAM environment: development staging production

deploy:
	@[ -z "$(environment)" ] && echo "Error: environment required" && exit 1 || true
	@echo "Deploying to $(environment)"
```

## Real-World Examples

### 1. Multi-Environment Application

```makefile
## Global parameters
## PARAM env: dev staging prod
## PARAM env TYPE=enum REQUIRED

## PARAM region: us-east-1 us-west-2 eu-west-1 ap-southeast-1
## PARAM region TYPE=enum DEFAULT=us-east-1

## PARAM dry_run: True False
## PARAM dry_run TYPE=bool DEFAULT=False

## TARGET deploy-backend
## PARAM replicas: 1 2 3 5 10
## PARAM replicas TYPE=enum DEFAULT=2

deploy-backend:
	@echo "Deploying backend to $(env) in $(region) with $(replicas) replicas"
	@if [ "$(dry_run)" = "True" ]; then \
		echo "[DRY RUN] Would execute: kubectl apply -f backend.yaml"; \
	else \
		kubectl apply -f backend.yaml; \
	fi

## TARGET deploy-frontend
## PARAM cdn: True False
## PARAM cdn TYPE=bool DEFAULT=True

deploy-frontend:
	@echo "Deploying frontend to $(env) in $(region)"
	@if [ "$(cdn)" = "True" ]; then \
		echo "Deploying with CDN"; \
		aws s3 sync dist/ s3://bucket-$(env)/ --region $(region); \
		aws cloudfront create-invalidation --distribution-id XXX; \
	else \
		echo "Deploying without CDN"; \
		aws s3 sync dist/ s3://bucket-$(env)/ --region $(region); \
	fi

## TARGET rollback
## PARAM version TYPE=enum REQUIRED
## PARAM version: v1.0.0 v1.0.1 v1.1.0 v2.0.0

rollback:
	@echo "Rolling back $(env) to version $(version)"
	kubectl rollout undo deployment/backend --to-revision=$(version)
```

Usage:
```bash
# Deploy backend to production with 5 replicas
make deploy-backend env=prod region=us-east-1 replicas=5

# Dry run deployment
make deploy-backend env=prod dry_run=True

# Deploy frontend with CDN
make deploy-frontend env=staging cdn=True

# Rollback to specific version
make rollback env=prod version=v1.0.1
```

### 2. Database Operations

```makefile
## PARAM db_host: localhost staging-db prod-db
## PARAM db_host TYPE=enum DEFAULT=localhost

## TARGET migrate
## PARAM direction: up down
## PARAM direction TYPE=enum REQUIRED

migrate:
	@echo "Running migrations $(direction) on $(db_host)"
	@if [ "$(direction)" = "up" ]; then \
		flyway migrate -url=jdbc:postgresql://$(db_host):5432/mydb; \
	else \
		flyway undo -url=jdbc:postgresql://$(db_host):5432/mydb; \
	fi

## TARGET seed
## PARAM dataset: minimal full test
## PARAM dataset TYPE=enum DEFAULT=minimal

seed:
	@echo "Seeding $(db_host) with $(dataset) dataset"
	@psql -h $(db_host) -f seeds/$(dataset).sql

## TARGET backup
## PARAM compress: True False
## PARAM compress TYPE=bool DEFAULT=True

backup:
	@echo "Backing up $(db_host)"
	@if [ "$(compress)" = "True" ]; then \
		pg_dump -h $(db_host) mydb | gzip > backup-$(shell date +%Y%m%d).sql.gz; \
	else \
		pg_dump -h $(db_host) mydb > backup-$(shell date +%Y%m%d).sql; \
	fi
```

Usage:
```bash
make migrate db_host=staging-db direction=up
make seed db_host=localhost dataset=full
make backup db_host=prod-db compress=True
```

### 3. Build & Test Pipeline

```makefile
## PARAM target_platform: linux darwin windows
## PARAM target_platform TYPE=enum DEFAULT=linux

## TARGET build
## PARAM arch: amd64 arm64 386
## PARAM arch TYPE=enum DEFAULT=amd64
## PARAM optimize: True False
## PARAM optimize TYPE=bool DEFAULT=True

build:
	@echo "Building for $(target_platform)/$(arch)"
	@if [ "$(optimize)" = "True" ]; then \
		GOOS=$(target_platform) GOARCH=$(arch) go build -ldflags="-s -w" -o bin/app; \
	else \
		GOOS=$(target_platform) GOARCH=$(arch) go build -o bin/app; \
	fi

## TARGET test
## PARAM coverage: True False
## PARAM coverage TYPE=bool DEFAULT=False
## PARAM verbose: True False
## PARAM verbose TYPE=bool DEFAULT=False

test:
	@FLAGS=""; \
	if [ "$(coverage)" = "True" ]; then FLAGS="$$FLAGS -cover -coverprofile=coverage.out"; fi; \
	if [ "$(verbose)" = "True" ]; then FLAGS="$$FLAGS -v"; fi; \
	go test $$FLAGS ./...

## TARGET lint
## PARAM fix: True False
## PARAM fix TYPE=bool DEFAULT=False

lint:
	@if [ "$(fix)" = "True" ]; then \
		golangci-lint run --fix; \
	else \
		golangci-lint run; \
	fi

## TARGET docker-build
## PARAM tag TYPE=enum REQUIRED
## PARAM tag: latest dev staging prod
## PARAM no_cache: True False
## PARAM no_cache TYPE=bool DEFAULT=False

docker-build:
	@if [ "$(no_cache)" = "True" ]; then \
		docker build --no-cache -t myapp:$(tag) .; \
	else \
		docker build -t myapp:$(tag) .; \
	fi
```

Usage:
```bash
# Build for different platforms
make build target_platform=darwin arch=arm64
make build target_platform=windows arch=amd64 optimize=False

# Run tests with coverage
make test coverage=True verbose=True

# Lint and auto-fix
make lint fix=True

# Build Docker image
make docker-build tag=prod no_cache=True
```

### 4. Monorepo Service Management

```makefile
## PARAM service: auth users orders payments notifications
## PARAM service TYPE=enum REQUIRED

## PARAM env: local docker k8s
## PARAM env TYPE=enum DEFAULT=local

## TARGET start
## PARAM debug: True False
## PARAM debug TYPE=bool DEFAULT=False

start:
	@echo "Starting $(service) service in $(env) environment"
	@if [ "$(debug)" = "True" ]; then \
		cd services/$(service) && DEBUG=* npm run dev; \
	else \
		cd services/$(service) && npm start; \
	fi

## TARGET stop
stop:
	@echo "Stopping $(service) service"
	@pkill -f "services/$(service)" || true

## TARGET logs
## PARAM follow: True False
## PARAM follow TYPE=bool DEFAULT=True
## PARAM lines: 10 50 100 500
## PARAM lines TYPE=enum DEFAULT=100

logs:
	@if [ "$(follow)" = "True" ]; then \
		tail -n $(lines) -f logs/$(service).log; \
	else \
		tail -n $(lines) logs/$(service).log; \
	fi

## TARGET deploy-service
## PARAM replicas: 1 2 3 5
## PARAM replicas TYPE=enum DEFAULT=2

deploy-service:
	@echo "Deploying $(service) with $(replicas) replicas to $(env)"
	@kubectl apply -f services/$(service)/k8s/deployment.yaml
	@kubectl scale deployment $(service) --replicas=$(replicas)
```

Usage:
```bash
# Start service with debug
make start service=auth debug=True

# Stop service
make stop service=orders

# Follow logs
make logs service=payments follow=True lines=500

# Deploy service
make deploy-service service=notifications env=k8s replicas=3
```

## Best Practices

### 1. Group Related Parameters

```makefile
## Database Configuration
## PARAM db_host: localhost staging prod
## PARAM db_port: 5432 3306
## PARAM db_name: myapp myapp_test

## Cache Configuration
## PARAM cache_enabled: True False
## PARAM cache_ttl: 60 300 3600
```

### 2. Use Descriptive Names

```makefile
# Good
## PARAM deployment_strategy: rolling blue-green canary
## PARAM enable_monitoring: True False

# Avoid
## PARAM s: r b c
## PARAM m: True False
```

### 3. Provide Sensible Defaults

```makefile
## PARAM log_level: debug info warn error
## PARAM log_level TYPE=enum DEFAULT=info

## PARAM max_retries: 1 3 5 10
## PARAM max_retries TYPE=enum DEFAULT=3
```

### 4. Document Complex Targets

```makefile
## TARGET deploy-all
## PARAM strategy: sequential parallel
## PARAM strategy TYPE=enum DEFAULT=sequential
## Deploy all microservices to the specified environment
## Strategy 'sequential' deploys one by one, 'parallel' deploys simultaneously

deploy-all:
	# implementation
```

## Common Patterns

### Pattern 1: Environment-Specific Behavior

```makefile
## PARAM env: dev prod
## PARAM env TYPE=enum REQUIRED

deploy:
	@if [ "$(env)" = "prod" ]; then \
		echo "Production deployment - running checks..."; \
		make lint test; \
	fi
	@echo "Deploying to $(env)"
```

### Pattern 2: Conditional Dependencies

```makefile
## PARAM with_cache: True False
## PARAM with_cache TYPE=bool DEFAULT=True

build: deps
	@if [ "$(with_cache)" = "True" ]; then \
		echo "Building with cache"; \
	else \
		echo "Building without cache"; \
		rm -rf .cache; \
	fi
	@npm run build
```

### Pattern 3: Multi-Stage Operations

```makefile
## TARGET deploy-full
## PARAM env: staging prod
## PARAM env TYPE=enum REQUIRED
## PARAM skip_tests: True False
## PARAM skip_tests TYPE=bool DEFAULT=False

deploy-full:
	@echo "Stage 1: Preparation"
	@make build env=$(env)
	@if [ "$(skip_tests)" = "False" ]; then \
		echo "Stage 2: Testing"; \
		make test env=$(env); \
	fi
	@echo "Stage 3: Deployment"
	@make deploy env=$(env)
	@echo "Stage 4: Verification"
	@make verify env=$(env)
```

### Pattern 4: Feature Flags

```makefile
## PARAM enable_feature_x: True False
## PARAM enable_feature_x TYPE=bool DEFAULT=False

## PARAM enable_feature_y: True False
## PARAM enable_feature_y TYPE=bool DEFAULT=False

deploy:
	@echo "Features: X=$(enable_feature_x) Y=$(enable_feature_y)"
	@export FEATURE_X=$(enable_feature_x) FEATURE_Y=$(enable_feature_y) && \
		./deploy.sh
```

## Tips & Tricks

### Tip 1: Use Help Target

```makefile
help:
	@echo "Available targets:"
	@awk -F: '/^[a-zA-Z0-9_-]+:/ {print "  " $$1}' Makefile
	@echo ""
	@echo "Parameters:"
	@awk '/^## PARAM / {print "  " $$0}' Makefile
```

### Tip 2: Validate Required Parameters

```makefile
## PARAM env TYPE=enum REQUIRED
deploy:
	@if [ -z "$(env)" ]; then \
		echo "Error: env parameter is required"; \
		exit 1; \
	fi
	@echo "Deploying to $(env)"
```

### Tip 3: Create Shortcuts

```makefile
## Quick shortcuts
dev: env=dev
dev: run

prod: env=prod
prod: deploy

staging: env=staging
staging: deploy
```

### Tip 4: Combine with Make Variables

```makefile
## PARAM version: 1.0.0 1.1.0 2.0.0
APP_NAME := myapp
REGISTRY := docker.io

docker-push:
	@docker tag $(APP_NAME):$(version) $(REGISTRY)/$(APP_NAME):$(version)
	@docker push $(REGISTRY)/$(APP_NAME):$(version)
```

## Debugging

### Check Generated Completions

```bash
# View the cache
cat ~/.cache/make-completion-enhanced.cache
```

### Test Parsing

```bash
# Extract all completion annotations
awk '/^## (PARAM|TARGET)/{print}' Makefile
```

### Verify Values

```bash
# See what values would be suggested
awk -F'|' '/api/{print}' ~/.cache/make-completion-enhanced.cache
```

## Next Steps

- Review the [README.md](README.md) for installation instructions
- Check [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- Explore the example [Makefile](Makefile) for more patterns
