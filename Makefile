.PHONY: help docker-up docker-down docker-reset docker-logs docker-status \
       network-init network-down channel-create chaincode-deploy \
       chaincode-test chaincode-lint chaincode-package \
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

chaincode-deploy: ## Deploy chaincode to the network
	./scripts/deploy-chaincode.sh

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
