SHELL := /usr/bin/env bash
# All is the first target in the file so it will get picked up when you just run 'make' on its own

all-test: clean tf-plan-test

.PHONY: clean
clean:
	rm -rf .terraform

.PHONY: tf-plan-test-aws
tf-plan-test-aws:
	terraform init -backend-config=backend_configs/test.hcl -reconfigure && terraform validate && terraform plan -var-file=vars/test.tfvars

.PHONY: tf-apply-test-aws
tf-apply-test-aws:
	terraform init -backend-config=backend_configs/test.hcl -reconfigure && terraform validate && terraform apply -var-file=vars/test.tfvars -auto-approve

.PHONY: tf-destroy-test-aws
tf-destroy-test-aws:
	terraform init -backend-config=backend_configs/test.hcl -reconfigure && terraform validate && terraform destroy -var-file=vars/test.tfvars -auto-approve