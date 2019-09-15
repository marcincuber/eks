# EKS Infrastructure

## EKS cluster, VPC and worker nodes configuration

EKS cluster and the VPC are templated with terraform. Worker nodes is partly written in cloudformation to take advantage or `rolling update` feature. All cloudformation templates are also deployed through terraform.

In order to enabled automatic upgrade of worker nodes, node dariner lambda is implemented and deployed as part of the stack. 

## Deployment

### Plan terraform templates

Ensure to assume the correct IAM role before deploying it manually.

```
make tf-plan-test
```

### Deploy terraform templates

```
make tf-apply-test
```