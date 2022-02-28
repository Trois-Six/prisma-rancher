.PHONY: help init plan all apply destroy graph fmt clean distclean
.DEFAULT_GOAL := all

REQUIRED_BINS := terraform
$(foreach bin,$(REQUIRED_BINS),\
    $(if $(shell command -v $(bin) 2> /dev/null),,$(error Please install `$(bin)`)))

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize modules and plugins
	@terraform init

plan: init ## Check what terraform is going to do
	@terraform plan

all: apply
apply: init ## Apply configuration
	@terraform apply -auto-approve

destroy: ## Remove all terraform ressources
	@terraform destroy -auto-approve

graph: ## Create objects tree graph
	@terraform graph | dot -Tpng > graph.png

SUBDIRS_MODULES := $(wildcard modules/*/.)
fmt: ## Indent files
	@terraform fmt
	@for dir in $(SUBDIRS_MODULES); do \
		terraform fmt $$dir; \
	done

distclean: ## Remove all dynamic content
	@rm -rf graph.png terraform.tfstate* .terraform crash.log

clean: destroy distclean ## Remove all resources
