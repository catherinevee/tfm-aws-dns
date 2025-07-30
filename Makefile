# Makefile for AWS DNS Terraform Module

.PHONY: help init validate format lint security test clean examples

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	terraform init

validate: ## Validate Terraform configuration
	terraform validate
	@echo "✅ Terraform validation passed"

format: ## Format Terraform code
	terraform fmt -recursive
	@echo "✅ Terraform formatting completed"

format-check: ## Check if Terraform code is formatted
	terraform fmt -check -recursive
	@echo "✅ Terraform format check passed"

lint: ## Run tflint on the module
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init; \
		tflint; \
		echo "✅ TFLint checks passed"; \
	else \
		echo "⚠️  TFLint not installed. Install with: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"; \
	fi

security: ## Run security checks with tfsec
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
		echo "✅ Security checks passed"; \
	else \
		echo "⚠️  tfsec not installed. Install with: curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash"; \
	fi

checkov: ## Run Checkov security checks
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d . --framework terraform; \
		echo "✅ Checkov security checks passed"; \
	else \
		echo "⚠️  Checkov not installed. Install with: pip install checkov"; \
	fi

test: validate format-check lint security ## Run all tests
	@echo "✅ All tests passed"

examples-init: ## Initialize all examples
	@for dir in examples/*/; do \
		echo "Initializing $$dir"; \
		cd "$$dir" && terraform init && cd ../..; \
	done

examples-validate: ## Validate all examples
	@for dir in examples/*/; do \
		echo "Validating $$dir"; \
		cd "$$dir" && terraform validate && cd ../..; \
	done

examples-format: ## Format all examples
	@for dir in examples/*/; do \
		echo "Formatting $$dir"; \
		cd "$$dir" && terraform fmt && cd ../..; \
	done

examples: examples-init examples-validate examples-format ## Initialize, validate, and format all examples
	@echo "✅ All examples processed"

docs: ## Generate documentation
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md .; \
		echo "✅ Documentation generated"; \
	else \
		echo "⚠️  terraform-docs not installed. Install from: https://terraform-docs.io/user-guide/installation/"; \
	fi

clean: ## Clean Terraform files
	find . -type f -name "*.tfstate*" -delete
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name ".terraform.lock.hcl" -delete
	@echo "✅ Cleaned Terraform files"

pre-commit: format validate lint ## Run pre-commit checks
	@echo "✅ Pre-commit checks completed"

ci: init validate format-check lint security examples-validate ## Run CI pipeline
	@echo "✅ CI pipeline completed successfully"
