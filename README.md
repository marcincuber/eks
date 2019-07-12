# EKS

Implementation of EKS using terraform and cloudformation. Fully functional templates to deploy your VPC and kubernetes clusters together with all the essential tags. Also, worker nodes are part of ASG with consists of spot and on-demand instances.

## Terraform 

All the templates can be found in [terraform](./terraform/). Ensure to reconfigure your backend as needed together with environment variables.

### Amazon EKS design, use of spot instances and cluster scaling

More about my configuration can be found in the blog post I have written recently -> [EKS design](https://medium.com/@marcincuber/amazon-eks-design-use-of-spot-instances-and-cluster-scaling-da7f3a72d061)

### IAM Roles for specific namespaces

https://medium.com/@marcincuber/amazon-eks-rbac-and-iam-access-f124f1164de7

### Kube2iam

More about kube2iam configuration can be found in the blog post I have written recently -> [EKS and kube2iam](https://medium.com/@marcincuber/amazon-eks-iam-roles-and-kube2iam-4ae5906318be)

### Sizing nodes i.e. max number of pods per instance

You can check how many ethernet interfaces and max IP per interface from [AvailableIpPerENI docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI)

#### Calculcation for worker nodes

Max Pods = ( Maximum supported  Network Interfaces for instance type ) * ( IPv4 Addresses per Interface ) - 1

Example for `m5.4xlarge`:
max interfaces 8
ips per interface 30

Max Pods = (Maximum supported  Network Interfaces for instance type ) * ( IPv4 Addresses per Interface ) - 1 = 8 * 30 - 1 = 239

## Kubernetes templates

All the templates for additional deployments/daemonsets can be found in [k8s_templates](./k8s_templates/).

To apply templates simply run `kubectl apply -f .` from a desired folder.

Important: in order to allow your worker nodes join the cluster, update [config_file](./aws-eks-resources/aws-auth-configmap.yaml) with the correct role arn.

### Rolling update article

https://medium.com/@endofcake/using-terraform-for-zero-downtime-updates-of-an-auto-scaling-group-in-aws-60faca582664

### EKS platforms information

https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html

### Worker nodes upgrades

https://docs.aws.amazon.com/eks/latest/userguide/update-stack.html

### CNI Upgrades

#### Verify version

```bash
kubectl describe daemonset aws-node -n kube-system | grep Image | cut -d "/" -f 2
```

https://docs.aws.amazon.com/eks/latest/userguide/cni-upgrades.html

[Latest releases](https://github.com/aws/amazon-vpc-cni-k8s/releases)

### Dashboard deployment

https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

## Generate kubeconfig file

On user's machine who has been added to EKS, they can configure .kube/config file using the following command:

```bash
$ aws eks list-clusters
$ aws eks update-kubeconfig --name ${cluster_name}
```

