# EKS

Implementation of EKS using terraform and cloudformation. Fully functional templates to deploy your VPC and kubernetes clusters together with all the essential tags. Also, worker nodes are part of ASG which consists of spot and on-demand instances.

## Terraform 

All the templates can be found in [terraform](./terraform/). Ensure to reconfigure your backend as needed together with environment variables.

Once you configure your environment variables in `./terraform/vars`, you can run `make tf-plan-test` or `make tf-apply-test` from `terraform` directory. Resources that will be created after applying templates:

1. VPC with public/private subnets and enabled flow logs
1. EKS controlplane
1. EKS worker nodes in private subnets (spot and ondemnd instances based on variables)
1. Dynamic basion host
1. Automatically configure aws-auth configmap for worker nodes to join the cluster
1. OpenID Connect provider which can be used to assign IAM roles to service accounts in k8s
1. NodeDrainer lambda which will drain worker nodes during rollingUpdate of the nodes
1. IAM Roles for service accounts such as aws-node, cluster-autoscaler, alb-ingress-controller, external-secrets (Role arns are used when you deploy kubernetes addons with Service Accounts that make use of OIDC provider)

### Amazon EKS design, use of spot instances and cluster scaling

More about my configuration can be found in the blog post I have written recently -> [EKS design](https://medium.com/@marcincuber/amazon-eks-design-use-of-spot-instances-and-cluster-scaling-da7f3a72d061)

### IAM Roles for specific namespaces

[Amazon EKS- RBAC with IAM access](https://medium.com/@marcincuber/amazon-eks-rbac-and-iam-access-f124f1164de7)

### IAM Roles for service accounts using OpenID Connect

[Using OIDC provider to allow service accounts to assume IAM role](https://medium.com/@marcincuber/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c)

### Kube2iam

More about kube2iam configuration can be found in the blog post I have written recently -> [EKS and kube2iam](https://medium.com/@marcincuber/amazon-eks-iam-roles-and-kube2iam-4ae5906318be)

## Kubernetes templates

All the templates for additional deployments/daemonsets can be found in [k8s_templates](./k8s_templates/).

To apply templates simply run `kubectl apply -f .` from a desired folder. Ensure to put in correct Role arn in service accounts configuration. Also, check that environment variables are correct.

### Useful resources

[EKS platforms information](https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html)
[Worker nodes upgrades](https://docs.aws.amazon.com/eks/latest/userguide/update-stack.html)

## Generate kubeconfig file

On user's machine who has been added to EKS, they can configure .kube/config file using the following command:

```bash
$ aws eks list-clusters
$ aws eks update-kubeconfig --name ${cluster_name}
```

