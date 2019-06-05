SHELL := /usr/bin/env bash
# All is the first target in the file so it will get picked up when you just run 'make' on its own

all-test: clean check_shell check_terraform check_base_files check_shebangs check_trailing_whitespace tf-apply-test

.PHONY: clean
clean:
	rm -rf terraform/.terraform

.PHONY: tf-plan-test
tf-plan-test:
	# Downloads the terraform providers and plan the configuration
	terraform init -backend-config=backend_configs/test.backend && terraform plan -var-file=env_vars/test.tfvars

.PHONY: tf-apply-test
tf-apply-test:
	# Downloads the terraform providers and applies the configuration
	terraform init -backend-config=backend_configs/test.backend && terraform apply -var-file=env_vars/test.tfvars

# .PHONY: tf-plan-prod
# tf-plan-prod:
# 	# Downloads the terraform providers and plan the configuration
# 	terraform init -backend-config=backend_configs/prod_backend && terraform plan -var-file=env_vars/prod.tfvars

# .PHONY: tf-apply-prod
# tf-apply-prod:
# 	# Downloads the terraform providers and applies the configuration
# 	terraform init -backend-config=backend_configs/prod_backend && terraform apply -var-file=env_vars/prod.tfvars

.PHONY: tf-destroy-test
tf-destroy-test:
	# Downloads the terraform providers and applies the configuration
	terraform -backend-config=backend_configs/test_backend destroy -var-file=env_vars/test.tfvars

.PHONY: check_shell
check_shell:
	@source scripts/make.sh && check_shell

.PHONY: check_terraform
check_terraform:
	@source scripts/make.sh && check_terraform

.PHONY: check_base_files
check_base_files:
	@source scripts/make.sh && basefiles

.PHONY: check_shebangs
check_shebangs:
	@source scripts/make.sh && check_bash

.PHONY: check_trailing_whitespace
check_trailing_whitespace:
	@source scripts/make.sh && check_trailing_whitespace
