# EKS

Implementation of EKS setup using `Terraform` and `Cloudformation`. Fully functional templates to deploy your `VPC` and `Kubernetes clusters` together with all the essential tags and addons. Also, worker nodes are part of AutoScallingGroup which consists of spot and on-demand instances.

Templates support deployment to different AWS partitions. I have tested it with `public` and `china` partitions. I am actively using this configuration to run EKS setup in Ireland(eu-west-1), North Virginia(us-east-1) and Beijing(cn-north-1).

### terraform-aws and terraform-k8s templates

Latest configuration templates used by me can be found in [terraform-aws](./terraform-aws/) for aws provider and [terraform-k8s](./terraform-k8s/) for kubernetes provider. Once you configure your environment variables in `./terraform-aws/vars` `./terraform-k8s/vars`, you can use makefile commands to run your deployments. Resources that will be created after applying templates:

You will find latest setup of following components:

1. VPC with public/private subnets, enabled flow logs and VPC endpoints for ECR and S3
1. EKS controlplane
1. EKS worker nodes in private subnets (spot and ondemnd instances based on variables)
1. Karpenter configuration for nodes
1. Option to used Managed Node Groups
1. Dynamic basion host
1. Automatically configure aws-auth configmap for worker nodes to join the cluster
1. OpenID Connect provider which can be used to assign IAM roles to service accounts in k8s
1. NodeDrainer lambda which will drain worker nodes during rollingUpdate of the nodes (This is only applicable to spot worker nodes, managed node groups do not require this lambda). Node drainer lambda is maintained in https://github.com/marcincuber/tf-k8s-node-drainer
1. IAM Roles for service accounts such as aws-node, cluster-autoscaler, alb-ingress-controller, external-secrets (Role arns are used when you deploy kubernetes addons with Service Accounts that make use of OIDC provider)
1. For spot termination handling use aws-node-termination-handler from [k8s_templates/aws-node-termination-handler](./k8s_templates/aws-node-termination-handler).
1. EKS cluster add-ons (CoreDNS + kube-proxy)

## Kubernetes YAML templates

All the templates for additional deployments/daemonsets can be found in [k8s_templates](./k8s_templates/).

To apply templates simply run `kubectl apply -f .` from a desired folder. Ensure to put in correct Role arn in service accounts configuration. Also, check that environment variables are correct. 

You will find templates for the following Kubernetes components:

* ALB ingress controller
* AWS Load Balancer controller
* AWS node termination handler
* Calico
* Cert Manager
* Cluster Autoscaler
* CoreDns
* Dashboard
* External-DNS
* External Secrets
* External Secrets Operator (helm chart using fluxv2)
* Karpenter (helm chart using fluxv2)
* Kube Proxy
* Kube2iam
* Metrics server
* NewRelic
* Reloader
* Spot Interrupt Handler
* Vertical Pod Autoscaler with cert-manager certificate
* VPC CNI Plugin
* Secrets CSI Driver

### Kubernetes components deployed using Helm

You can find even more K8s components at https://github.com/marcincuber/kubernetes-fluxv2
I have built this repository to show how to develop a successful configuration for your cluster using GitOps FluxV2 and Helm.

## Docs and other additional resources

Check out my stories on medium if you interested in finding out more on specific topics.

### Amazon EKS upgrade 1.26 to 1.27

[Amazon EKS upgrade journey from 1.26 to 1.27](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-26-to-1-27-chill-vibes-46f3f979afac)

### Amazon EKS upgrade 1.25 to 1.26

[Amazon EKS upgrade journey from 1.25 to 1.26](https://medium.com/@marcincuber/amazon-eks-upgrade-journey-from-1-25-to-1-26-electrifying-79b287084eef)

### Amazon EKS upgrade 1.24 to 1.25

[Amazon EKS upgrade journey from 1.24 to 1.25](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-24-to-1-25-e1bcccc2f384)

### Amazon EKS upgrade 1.23 to 1.24

[Amazon EKS upgrade journey from 1.23 to 1.24](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-23-to-1-24-b7b0b1afa5b4)

### Amazon EKS upgrade 1.22 to 1.23

[Amazon EKS upgrade journey from 1.22 to 1.23](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-22-to-1-23-3b9eaa8c57de)

### Amazon EKS upgrade 1.21 to 1.22

[Amazon EKS upgrade journey from 1.21 to 1.22](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-21-to-1-22-9546da932af6)

### Amazon EKS upgrade 1.20 to 1.21

[Amazon EKS upgrade journey from 1.20 to 1.21](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-20-to-1-21-caf1475deaa4)

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

