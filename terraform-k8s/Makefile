SHELL := /usr/bin/env bash
# All is the first target in the file so it will get picked up when you just run 'make' on its own

all-test: clean tf-plan-test-k8s

.PHONY: clean
clean:
	rm -rf .terraform

.PHONY: tf-plan-test-k8s
tf-plan-test-k8s:
	terraform init -backend-config=backend_configs/test.hcl -reconfigure && terraform validate && terraform plan -var-file=vars/test.tfvars

.PHONY: tf-apply-test-k8s
tf-apply-test-k8s:
	terraform init -backend-config=backend_configs/test.hcl -reconfigure && terraform validate && terraform apply -var-file=vars/test.tfvars -auto-approve

.PHONY: tf-destroy-test-k8s
tf-destroy-test:
	terraform init -backend-config=backend_configs/test.hcl -reconfigure && terraform validate && terraform destroy -var-file=vars/test.tfvars -auto-approve