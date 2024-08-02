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
	docker run --rm -v $$(pwd):/data -t ghcr.io/terraform-linters/tflint


.PHONY: test 
test: ## Run the tests
	terraform test --verbose

.PHONY: formatting
formatting:
	@echo "Checking formatting"
	terraform fmt -check
	@echo "Formatting OK"

.PHONY: check
check: formatting test

