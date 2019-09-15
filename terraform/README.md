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

## Creating new environment

Full documentation can be found [here](https://nidigitalsolutions.jira.com/wiki/spaces/NUKT/pages/edit/1336770579?draftId=1337163825&draftShareId=e3764749-911c-4551-9d9e-d7cd8c9eb2fa&)

## AWS Account structure

#### aws-digital-dev-cloudengpltaforms (015774327972)

Contains: EKS test environment

#### aws-digital-dev-digiengplatform (720262317718)

Contains: EKS dev environment 

#### aws-digital-prod-digiengplatform (474887192380)

Contains: EKS prod environment
