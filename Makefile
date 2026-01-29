.PHONY: help docker-up docker-down docker-reset docker-logs docker-status \
       network-init network-down channel-create chaincode-deploy \
       chaincode-upgrade chaincode-rollback chaincode-status \
       chaincode-test chaincode-lint chaincode-package \
       ccaas-build ccaas-deploy ccaas-logs ccaas-stop \
       api-install api-dev api-test api-lint \
       generate-data test lint integration-test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Network Lifecycle
# =============================================================================

network-init: ## Initialize Fabric network (generate crypto, channel artifacts)
	./scripts/network-init.sh

network-down: ## Stop network and clean up (use CLEAN=crypto to also remove crypto material)
	./scripts/network-down.sh

# =============================================================================
# Docker Operations
# =============================================================================

docker-up: ## Start local Fabric network
	docker compose -f infrastructure/docker/docker-compose.yaml up -d

docker-down: ## Stop local Fabric network
	docker compose -f infrastructure/docker/docker-compose.yaml down

docker-reset: ## Stop network, remove volumes, and restart
	docker compose -f infrastructure/docker/docker-compose.yaml down -v
	docker compose -f infrastructure/docker/docker-compose.yaml up -d

docker-logs: ## Tail logs from all Fabric containers
	docker compose -f infrastructure/docker/docker-compose.yaml logs -f

docker-status: ## Show status of Fabric containers
	docker compose -f infrastructure/docker/docker-compose.yaml ps

docker-elk: ## Start ELK stack
	docker compose -f infrastructure/docker/docker-compose.elk.yaml up -d

# =============================================================================
# Channel Operations
# =============================================================================

channel-create: ## Create channel and join all peers
	./scripts/create-channel.sh

# =============================================================================
# Chaincode Operations
# =============================================================================

chaincode-test: ## Run Go chaincode tests
	cd chaincode/niop && go test ./...
	cd chaincode/shared && go test ./...
	@# ctoc has no packages yet - uncomment when implemented
	@# cd chaincode/ctoc && go test ./...

chaincode-lint: ## Lint Go chaincode
	cd chaincode/niop && go vet ./...
	cd chaincode/shared && go vet ./...
	@# ctoc has no packages yet - uncomment when implemented
	@# cd chaincode/ctoc && go vet ./...

chaincode-package: ## Package chaincode for deployment
	@echo "Packaging CTOC chaincode..."
	cd chaincode/ctoc && go mod vendor
	@echo "Packaging NIOP chaincode..."
	cd chaincode/niop && go mod vendor
	@echo "Chaincode packages ready for deployment"

chaincode-deploy: ## Deploy chaincode to the network (traditional mode)
	./scripts/deploy-chaincode.sh

chaincode-upgrade: ## Upgrade chaincode (use VERSION=x.y and optionally PATH=...)
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make chaincode-upgrade VERSION=1.1 [PATH=chaincode/niop] [NAME=niop]"; \
		exit 1; \
	fi
	./scripts/upgrade-chaincode.sh -n $(or $(NAME),niop) -v $(VERSION) $(if $(PATH),-p $(PATH))

chaincode-rollback: ## Rollback chaincode (requires VERSION and TAG or PATH)
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make chaincode-rollback VERSION=1.0 TAG=v1.0.0"; \
		echo "   or: make chaincode-rollback VERSION=1.0 PATH=/path/to/old/code"; \
		exit 1; \
	fi
	@if [ -z "$(TAG)" ] && [ -z "$(PATH)" ]; then \
		echo "Error: Either TAG or PATH must be specified"; \
		exit 1; \
	fi
	./scripts/rollback-chaincode.sh -n $(or $(NAME),niop) -v $(VERSION) $(if $(TAG),-t $(TAG)) $(if $(PATH),-p $(PATH))

chaincode-status: ## Show current chaincode status on the network
	@echo "Querying committed chaincode..."
	@docker exec peer0.org1.tolling.network peer lifecycle chaincode querycommitted \
		--channelID tolling --name niop 2>/dev/null || echo "Chaincode not deployed or network not running"

# =============================================================================
# Chaincode as a Service (ccaas) Operations
# =============================================================================

ccaas-build: ## Build chaincode Docker image for ccaas
	@echo "Building NIOP chaincode Docker image..."
	docker build -t niop-chaincode:$(or $(VERSION),1.0) \
		-f chaincode/niop/ccaas/Dockerfile .
	@echo "Chaincode image built: niop-chaincode:$(or $(VERSION),1.0)"

ccaas-deploy: ## Deploy chaincode using ccaas (chaincode as a service)
	./scripts/deploy-ccaas.sh $(if $(VERSION),-v $(VERSION)) $(if $(SEQUENCE),-s $(SEQUENCE))

ccaas-logs: ## Tail logs from chaincode container
	docker logs -f niop-chaincode

ccaas-stop: ## Stop the chaincode container
	docker stop niop-chaincode 2>/dev/null || true
	docker rm niop-chaincode 2>/dev/null || true

ccaas-restart: ## Restart the chaincode container (preserves package ID)
	@if [ -z "$(CHAINCODE_ID)" ]; then \
		echo "Usage: make ccaas-restart CHAINCODE_ID=<package_id>"; \
		echo "Get the package ID from: docker exec cli peer lifecycle chaincode queryinstalled"; \
		exit 1; \
	fi
	docker stop niop-chaincode 2>/dev/null || true
	docker rm niop-chaincode 2>/dev/null || true
	CHAINCODE_ID=$(CHAINCODE_ID) CC_VERSION=$(or $(VERSION),1.0) \
		docker compose -f infrastructure/docker/docker-compose.yaml \
		--profile chaincode up -d niop-chaincode

# =============================================================================
# API Operations
# =============================================================================

api-install: ## Install API dependencies
	cd api && npm install

api-dev: ## Start API in development mode
	cd api && npm run start:dev

api-test: ## Run API tests
	cd api && npm test

api-lint: ## Lint API code
	cd api && npm run lint

# =============================================================================
# Tools
# =============================================================================

generate-data: ## Generate synthetic test data
	cd tools/data-generation && python3 simple_data_gen.py

# =============================================================================
# Aggregate Targets
# =============================================================================

test: chaincode-test ## Run all tests (api-test added when API implemented)

lint: chaincode-lint ## Run all linters (api-lint added when API implemented)

integration-test: ## Run integration tests against running network
	./scripts/integration-test.sh
