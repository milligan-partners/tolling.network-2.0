.PHONY: help docker-up docker-down chaincode-test api-dev api-test lint generate-data test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker
docker-up: ## Start local Fabric network
	docker compose -f infrastructure/docker/docker-compose.yaml up -d

docker-down: ## Stop local Fabric network
	docker compose -f infrastructure/docker/docker-compose.yaml down

docker-elk: ## Start ELK stack
	docker compose -f infrastructure/docker/docker-compose.elk.yaml up -d

# Chaincode
chaincode-test: ## Run Go chaincode tests
	cd chaincode/ctoc && go test ./...
	cd chaincode/niop && go test ./...
	cd chaincode/shared && go test ./...

chaincode-lint: ## Lint Go chaincode
	cd chaincode/ctoc && go vet ./...
	cd chaincode/niop && go vet ./...
	cd chaincode/shared && go vet ./...

# API
api-install: ## Install API dependencies
	cd api && npm install

api-dev: ## Start API in development mode
	cd api && npm run start:dev

api-test: ## Run API tests
	cd api && npm test

api-lint: ## Lint API code
	cd api && npm run lint

# Tools
generate-data: ## Generate synthetic test data
	cd tools/data-generation && python3 simple_data_gen.py

# Aggregate
test: chaincode-test api-test ## Run all tests

lint: chaincode-lint api-lint ## Run all linters
