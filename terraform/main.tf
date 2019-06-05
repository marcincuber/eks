terraform {
  required_version = "~> 0.12.0"

  backend "remote" {
    hostname = "app.terraform.io"
  }
}

provider "aws" {
  version = "~> 2.12"
  region  = var.region
}

#####
# VPC configuration for EKS
#####

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.2.0"

  name = "${var.cluster_name}-${var.environment}-vpc"

  azs = var.availability_zones

  cidr            = "10.250.0.0/18"
  private_subnets = ["10.250.32.0/22", "10.250.36.0/22", "10.250.40.0/22"]
  public_subnets  = ["10.250.4.0/22", "10.250.8.0/22", "10.250.12.0/22"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  enable_vpn_gateway = true

  single_nat_gateway     = var.vpc_single_nat_gateway
  one_nat_gateway_per_az = var.vpc_one_nat_gateway_per_az

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
    },
  )

  # VPC endpoint for S3
  enable_s3_endpoint = false

  # VPC endpoint for DynamoDB
  enable_dynamodb_endpoint = false

}

#####
# EKS Control Plane security group
#####

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-${var.environment}-control-plane-sg"
  description = "Control Plane SG- Cluster communication with worker nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  to_port                  = 443
  type                     = "ingress"
}

#####
# EKS Worker Nodes security group
#####

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-${var.environment}-worker-node-sg"
  description = "Security group for all worker nodes in the cluster"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "node-ingress-cluster-https" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane on port 443"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

#####
# EKS Cluster
#####

resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  name                      = "${var.cluster_name}-${var.environment}"
  role_arn                  = aws_iam_role.cluster.arn
  version                   = var.eks_version

  vpc_config {
    subnet_ids              = flatten([module.vpc.public_subnets, module.vpc.private_subnets])
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
  }
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-${var.environment}-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.cluster.name
}

#####
# EKS Worker Nodes Resources
#####

resource "aws_iam_role" "worker_node" {
  name = "${var.cluster_name}-${var.environment}-worker-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_instance_profile" "worker_node" {
name = "${var.cluster_name}-${var.environment}-instance-profile"
role = aws_iam_role.worker_node.name
}

resource "random_id" "role_suffix" {
  byte_length = 8
}

resource "aws_iam_policy" "worker_node_custom_policy" {
  name   = "${var.cluster_name}-${var.environment}-custom-policy-${random_id.role_suffix.hex}"
  policy = templatefile("policies/worker_node_custom_policy.json", {})
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-custom-policy" {
  policy_arn = aws_iam_policy.worker_node_custom_policy.arn
  role       = aws_iam_role.worker_node.name
}

#####
# EKS worker nodes cloudformatino stack
#####

resource "aws_cloudformation_stack" "spot_worker" {
  name         = "${var.cluster_name}-${var.environment}-spot-worker-nodes-stack"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    KeyName       = var.ssh_key_name
    NodeImageId   = var.ami_id
    ClusterName   = aws_eks_cluster.cluster.id
    NodeGroupName = "${var.cluster_name}-${var.environment}-spot-node-group"

    ASGAutoAssignPublicIp = "no"
    NodeInstanceType      = var.spot_worker_instance_type

    Subnets                          = join(",", module.vpc.private_subnets)
    VpcId                            = module.vpc.vpc_id
    NodeInstanceProfileArn           = aws_iam_instance_profile.worker_node.arn
    ClusterControlPlaneSecurityGroup = aws_security_group.cluster.id
    ExistingNodeSecurityGroups       = aws_security_group.node.id

    InstanceTypesOverride               = "m5.4xlarge,m5d.4xlarge,m5a.4xlarge,m5ad.4xlarge"
    OnDemandBaseCapacity                = "1"
    OnDemandPercentageAboveBaseCapacity = "0"
    SpotInstancePools                   = "4"

    NodeAutoScalingGroupDesiredCapacity = "9"
    NodeAutoScalingGroupMinSize         = "1"
    NodeAutoScalingGroupMaxSize         = "10"

    BootstrapArgumentsForOnDemand = "--use-max-pods '239' --kubelet-extra-args '--node-labels=lifecycle=OnDemand --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --kube-reserved cpu=250m,memory=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<0.2Gi,nodefs.available<10%'"
    BootstrapArgumentsForSpot     = "--use-max-pods '239' --kubelet-extra-args '--node-labels=lifecycle=Ec2Spot --register-with-taints=spotInstance=true:PreferNoSchedule --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --kube-reserved cpu=250m,memory=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<0.2Gi,nodefs.available<10%'"
  }

  template_body = file("cfm/worker-node-spot-stack.yaml")

  tags = var.tags

  timeouts {
    create = "60m"
    update = "2h"
    delete = "2h"
  }
}
