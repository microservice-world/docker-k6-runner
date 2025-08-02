# K6 Runner - Professional Load Testing Container
# Makefile for development, testing, and deployment

.PHONY: help build test clean push run examples lint security

# Variables
IMAGE_NAME := k6-runner
IMAGE_TAG := latest
REGISTRY := ghcr.io
ORG := your-org
FULL_IMAGE := $(REGISTRY)/$(ORG)/$(IMAGE_NAME):$(IMAGE_TAG)

# Docker build arguments
BUILD_DATE := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
VCS_REF := $(shell git rev-parse --short HEAD)
VERSION := $(shell git describe --tags --always --dirty)

help: ## Show this help message
	@echo "K6 Runner - Professional Load Testing Container"
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make build              # Build the container"
	@echo "  make test               # Run tests"
	@echo "  make run-examples       # Run example tests"
	@echo "  make clean              # Clean up containers and volumes"

build: ## Build the K6 Runner container
	@echo "🔨 Building K6 Runner container..."
	docker build \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VERSION="$(VERSION)" \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(IMAGE_NAME):latest \
		.
	@echo "✅ Build complete: $(IMAGE_NAME):$(IMAGE_TAG)"

build-multi: ## Build multi-platform container (requires buildx)
	@echo "🔨 Building multi-platform K6 Runner container..."
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VERSION="$(VERSION)" \
		-t $(FULL_IMAGE) \
		--push \
		.
	@echo "✅ Multi-platform build complete and pushed"

test: build ## Run container tests
	@echo "🧪 Running K6 Runner tests..."
	
	# Test basic functionality
	@echo "Testing basic commands..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) version
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) help
	
	# Test with httpbin
	@echo "Testing load test execution..."
	mkdir -p test-output test-reports
	docker run --rm \
		-v "$(PWD)/examples:/scripts" \
		-v "$(PWD)/test-reports:/reports" \
		-v "$(PWD)/test-output:/output" \
		-e BASE_URL=https://httpbin.org \
		$(IMAGE_NAME):$(IMAGE_TAG) test smoke --duration 30s
	
	# Verify reports were generated
	@if [ -f "test-reports/smoke-*.html" ]; then \
		echo "✅ HTML report generated successfully"; \
	else \
		echo "❌ HTML report generation failed"; \
		exit 1; \
	fi
	
	@echo "✅ All tests passed!"

test-with-compose: ## Run tests using docker-compose
	@echo "🧪 Running tests with docker-compose..."
	
	# Start test environment
	docker-compose --profile testing up -d test-api
	
	# Wait for test API to be ready
	@echo "Waiting for test API to be ready..."
	sleep 10
	
	# Run smoke test
	docker-compose --profile testing run --rm k6-runner test smoke --duration 30s
	
	# Run load test
	docker-compose --profile testing run --rm k6-runner test load --duration 2m
	
	# Cleanup
	docker-compose --profile testing down
	
	@echo "✅ Compose tests completed!"

run-examples: build ## Run example test scripts
	@echo "🚀 Running example tests..."
	
	# Ensure directories exist
	mkdir -p reports output
	
	# Run smoke test
	@echo "Running smoke test..."
	docker run --rm \
		-v "$(PWD)/examples:/scripts" \
		-v "$(PWD)/reports:/reports" \
		-v "$(PWD)/output:/output" \
		-e BASE_URL=https://httpbin.org \
		$(IMAGE_NAME):$(IMAGE_TAG) test smoke
	
	# Run load test
	@echo "Running load test..."
	docker run --rm \
		-v "$(PWD)/examples:/scripts" \
		-v "$(PWD)/reports:/reports" \
		-v "$(PWD)/output:/output" \
		-e BASE_URL=https://httpbin.org \
		$(IMAGE_NAME):$(IMAGE_TAG) test load --duration 2m
	
	@echo "✅ Example tests completed! Check reports/ directory for results."

validate: ## Validate test scripts
	@echo "✅ Validating test scripts..."
	
	# Check if example scripts exist
	@if [ ! -d "examples" ]; then \
		echo "❌ Examples directory not found"; \
		exit 1; \
	fi
	
	# Validate each JavaScript file
	@for script in examples/*.js; do \
		if [ -f "$$script" ]; then \
			echo "Validating $$script..."; \
			docker run --rm \
				-v "$(PWD)/examples:/scripts" \
				$(IMAGE_NAME):$(IMAGE_TAG) validate "$$(basename $$script)"; \
		fi \
	done
	
	@echo "✅ All scripts validated successfully!"

lint: ## Lint Dockerfile and shell scripts
	@echo "🧹 Linting code..."
	
	# Lint Dockerfile
	@if command -v hadolint >/dev/null 2>&1; then \
		echo "Linting Dockerfile..."; \
		hadolint Dockerfile; \
	else \
		echo "⚠️  hadolint not found, skipping Dockerfile lint"; \
	fi
	
	# Lint shell scripts
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Linting shell scripts..."; \
		find scripts/ -name "*.sh" -exec shellcheck {} \;; \
	else \
		echo "⚠️  shellcheck not found, skipping shell script lint"; \
	fi
	
	@echo "✅ Linting completed!"

security: build ## Run security scans
	@echo "🔒 Running security scans..."
	
	# Run Trivy security scan
	@if command -v trivy >/dev/null 2>&1; then \
		echo "Running Trivy security scan..."; \
		trivy image $(IMAGE_NAME):$(IMAGE_TAG); \
	else \
		echo "⚠️  Trivy not found, skipping security scan"; \
		echo "Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"; \
	fi

push: build ## Push container to registry
	@echo "📤 Pushing to registry..."
	
	# Tag for registry
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(FULL_IMAGE)
	
	# Push to registry
	docker push $(FULL_IMAGE)
	
	@echo "✅ Pushed to $(FULL_IMAGE)"

run: build ## Run interactive K6 Runner shell
	@echo "🐚 Starting interactive K6 Runner shell..."
	docker run -it --rm \
		-v "$(PWD)/examples:/scripts" \
		-v "$(PWD)/reports:/reports" \
		-v "$(PWD)/output:/output" \
		--entrypoint /bin/bash \
		$(IMAGE_NAME):$(IMAGE_TAG)

dashboard: build ## Start K6 web dashboard
	@echo "🌐 Starting K6 web dashboard on http://localhost:5665"
	docker-compose --profile dashboard up k6-dashboard

reports-server: ## Start nginx server for viewing reports
	@echo "🌐 Starting reports server on http://localhost:8082"
	docker-compose --profile reports up report-server

dev: ## Start full development environment
	@echo "🚀 Starting full development environment..."
	docker-compose --profile testing up -d
	@echo "✅ Development environment started:"
	@echo "  📊 Test API: http://localhost:8080"
	@echo "  📄 Sample App: http://localhost:8081"
	@echo "  📈 Reports: http://localhost:8082"
	@echo ""
	@echo "Run tests with:"
	@echo "  docker-compose --profile testing run --rm k6-runner test load"

stop: ## Stop development environment
	@echo "🛑 Stopping development environment..."
	docker-compose --profile testing down
	docker-compose --profile dashboard down
	docker-compose --profile reports down

clean: ## Clean up containers, images, and volumes
	@echo "🧹 Cleaning up..."
	
	# Stop all related containers
	docker-compose down --remove-orphans
	
	# Remove test artifacts
	rm -rf test-output test-reports
	
	# Remove dangling images
	docker image prune -f
	
	# Remove development volumes
	docker volume prune -f
	
	@echo "✅ Cleanup completed!"

clean-reports: ## Clean old reports and outputs
	@echo "🧹 Cleaning old reports..."
	docker run --rm \
		-v "$(PWD)/reports:/reports" \
		-v "$(PWD)/output:/output" \
		$(IMAGE_NAME):$(IMAGE_TAG) cleanup all --max-age 7
	@echo "✅ Reports cleaned!"

stats: ## Show disk usage statistics
	@echo "📊 Disk usage statistics..."
	docker run --rm \
		-v "$(PWD)/reports:/reports" \
		-v "$(PWD)/output:/output" \
		$(IMAGE_NAME):$(IMAGE_TAG) cleanup stats

setup-examples: ## Create example test scripts
	@echo "📝 Setting up example test scripts..."
	mkdir -p examples config
	
	# Create basic load test example
	cat > examples/basic-load-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '3m', target: 20 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.1'],
  },
};

export default function () {
  const response = http.get(`${__ENV.BASE_URL}/get`);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
  });
  
  sleep(1);
}
EOF
	
	# Create nginx config for reports server
	mkdir -p config
	cat > config/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
	
	@echo "✅ Example files created in examples/ and config/ directories"

install-tools: ## Install development tools (hadolint, shellcheck, trivy)
	@echo "🔧 Installing development tools..."
	
	# Install hadolint (Dockerfile linter)
	@if ! command -v hadolint >/dev/null 2>&1; then \
		echo "Installing hadolint..."; \
		wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64; \
		chmod +x /usr/local/bin/hadolint; \
	fi
	
	# Install shellcheck
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "Installing shellcheck..."; \
		sudo apt-get update && sudo apt-get install -y shellcheck; \
	fi
	
	# Install trivy
	@if ! command -v trivy >/dev/null 2>&1; then \
		echo "Installing trivy..."; \
		curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin; \
	fi
	
	@echo "✅ Development tools installed!"

version: ## Show version information
	@echo "K6 Runner Build Information:"
	@echo "  Version: $(VERSION)"
	@echo "  Build Date: $(BUILD_DATE)"
	@echo "  VCS Ref: $(VCS_REF)"
	@echo "  Image: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "  Registry: $(FULL_IMAGE)"

# Default target
.DEFAULT_GOAL := help