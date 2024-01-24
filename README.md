# EKS

Implementation of EKS setup using Terraform. Terraform module located in [terraform](./terraform/) directory supports deployment to different AWS partitions. I have tested it with `commercial` and `china` partitions. I am actively using this configuration to run EKS setup in Ireland(eu-west-1), London(eu-west-2), North Virginia(us-east-1) and Beijing(cn-north-1).

## Module details

Module creates:

* VPC
* VPC Endpoints- S3, ECR, STS, APS, GuardDuty
* EKS Cluster
* EKS Node Group to run cluster critical services
* EKS Addons- coredns, kube-proxy, guardduty, aws-ebs-csi-driver, adot (requires cert-manger to be installed), kubecost, cloudwatch observability, snapshot-controller and identity agent
* IAM Roles for worker nodes and Karpenter nodes
* Additional IAM Roles for operators- load-balancer-controller, external-dns, cert-manager, adot-collector
* SQS queue configuration to be used with Karpeneter while utlising Spot Instances.

## Kubernetes addons and operators

I am utilising Flux2 to deploy all additional configurations. You can find them at https://github.com/marcincuber/kubernetes-fluxv2
I have built this as a separate repository to show how to develop a successful configuration for your own cluster using GitOps FluxV2 and Helm.

You will find configurations for:

* AWS Load Balancer controller
* AWS node termination handler
* Cert Manager
* External-DNS
* External Secrets Operator
* Metrics server
* Reloader
* VPC CNI Plugin
* EBS CSI Driver
* and more :)

## Docs and other additional resources

Check out my stories on medium if you interested in finding out more on specific topics.

### Amazon EKS upgrade 1.28 to 1.29

[Amazon EKS upgrade journey from 1.28 to 1.29](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-28-to-1-29-say-hello-to-mandala-858ae0579f4f)

### Amazon EKS upgrade 1.27 to 1.28

[Amazon EKS upgrade journey from 1.27 to 1.28](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-27-to-1-28-welcoming-planternetes-44985e11463a)

### Amazon EKS upgrade 1.26 to 1.27

[Amazon EKS upgrade journey from 1.26 to 1.27](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-26-to-1-27-chill-vibes-46f3f979afac)

### Amazon EKS upgrade 1.25 to 1.26

[Amazon EKS upgrade journey from 1.25 to 1.26](https://medium.com/@marcincuber/amazon-eks-upgrade-journey-from-1-25-to-1-26-electrifying-79b287084eef)

### Amazon EKS upgrade 1.24 to 1.25

[Amazon EKS upgrade journey from 1.24 to 1.25](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-24-to-1-25-e1bcccc2f384)

### Karpenter Upgrade guide from alpha to beta API version

[Migrate Karpenter resources from alpha to beta API version](https://medium.com/@marcincuber/amazon-eks-migrating-karpenter-resources-from-alpha-to-beta-api-version-7bf320bbecb5)

### Amazon EKS Addons
[Amazon EKS Addons](https://marcincuber.medium.com/amazon-eks-add-ons-implemented-with-terraform-66a49fad4174)

### EKS + Kube-bench

[Kube-bench implementation with EKS](https://itnext.io/aws-eks-and-kube-bench-a7ae840f0f1)

### Amazon EKS design, use of spot instances and cluster scaling

More about my configuration can be found in the blog post I have written recently -> [EKS design](https://medium.com/@marcincuber/amazon-eks-design-use-of-spot-instances-and-cluster-scaling-da7f3a72d061)

### IAM Roles for specific namespaces

[Amazon EKS- RBAC with IAM access](https://medium.com/@marcincuber/amazon-eks-rbac-and-iam-access-f124f1164de7)

### IAM Roles for service accounts using OpenID Connect

[Using OIDC provider to allow service accounts to assume IAM role](https://medium.com/@marcincuber/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c)

### Kube2iam

More about kube2iam configuration can be found in the blog post I have written recently -> [EKS and kube2iam](https://medium.com/@marcincuber/amazon-eks-iam-roles-and-kube2iam-4ae5906318be)

### External DNS

[Amazon EKS, setup external DNS with OIDC provider and kube2iam](https://medium.com/swlh/amazon-eks-setup-external-dns-with-oidc-provider-and-kube2iam-f2487c77b2a1)

### EKS Managed Node Groups

[Amazon EKS + managed node groups](https://itnext.io/amazon-eks-managed-node-groups-87943e3f3360)

Terraform module written by me can be found in -> https://registry.terraform.io/modules/umotif-public/eks-node-group

### Gitlab runners on EKS

[Kubernetes GitLab Runners on Amazon EKS](https://medium.com/@marcincuber/kubernetes-gitlab-runners-on-amazon-eks-5ba7f0bff30e)

### Useful resources

[EKS platforms information](https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html)
[Worker nodes upgrades](https://docs.aws.amazon.com/eks/latest/userguide/update-stack.html)

## Generate kubeconfig file

On user's machine who has been added to EKS, they can configure .kube/config file using the following command:

```bash
$ aws eks list-clusters
$ aws eks update-kubeconfig --name ${cluster_name}
```
