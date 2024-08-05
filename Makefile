OK?=\033[0;32m[Ok]\033[0m

##@ General
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


##@ Dev
.PHONY: doc
doc: ## Generate the doc
	docker run --rm --volume "$$(pwd):/terraform-docs" -u $$(id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs > README.md


.PHONY: lint 
lint: ## Lint the codebase
	@echo "\033[0;33m[Linting...]\033[0m"
	@if command -v tflint > /dev/null; then \
		tflint; \
	else \
		docker run --rm -v $$(pwd):/data -t ghcr.io/terraform-linters/tflint; \
	fi
	@echo "${OK}"

.PHONY: validate 
validate: 
	@echo "\033[0;33m[Terraform validate...]\033[0m"
	@terraform validate 
	@echo "${OK}"

.PHONY: test 
test: ## Run the tests
	@echo "\033[0;33m[Running tests...]\033[0m"
	@terraform test --verbose
	@echo "${OK}"

.PHONY: formatting
formatting:
	@echo "\033[0;33m[Terraform fmt...]\033[0m"
	@terraform fmt -check 
	@echo "${OK}"


.PHONY: check-no-tests
check-no-tests: formatting validate lint

.PHONY: check
check: check-no-tests test
