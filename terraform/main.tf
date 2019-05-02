terraform {
  backend "s3" {}

  required_version = "~> 0.11.13"
}

provider "aws" {
  region = "${var.region}"
}

#####
# VPC configuration for EKS
#####

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.60.0"

  name = "${var.cluster_name}-${var.environment}-vpc"

  cidr = "10.250.0.0/18"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.250.32.0/22", "10.250.36.0/22", "10.250.40.0/22"]
  public_subnets  = ["10.250.4.0/22", "10.250.8.0/22", "10.250.12.0/22"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  enable_vpn_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = "${merge(var.tags, map("kubernetes.io/cluster/${var.cluster_name}-${var.environment}", "shared"))}"
}

#####
# EKS Control Plane security group
#####

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-${var.environment}-control-plane-sg"
  description = "Control Plane SG- Cluster communication with worker nodes"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("kubernetes.io/cluster/${var.cluster_name}-${var.environment}", "owned"))}"
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster.id}"
  source_security_group_id = "${aws_security_group.node.id}"
  to_port                  = 443
  type                     = "ingress"
}

#####
# EKS Worker Nodes security group
#####

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-${var.environment}-worker-node-sg"
  description = "Security group for all worker nodes in the cluster"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("kubernetes.io/cluster/${var.cluster_name}-${var.environment}", "owned"))}"
}

resource "aws_security_group_rule" "node-ingress-cluster-https" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane on port 443"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.node.id}"
  source_security_group_id = "${aws_security_group.cluster.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.node.id}"
  source_security_group_id = "${aws_security_group.node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.node.id}"
  source_security_group_id = "${aws_security_group.cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

#####
# EKS Cluster
#####

resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  name                      = "${var.cluster_name}-${var.environment}"
  role_arn                  = "${aws_iam_role.cluster.arn}"
  version                   = "${var.eks_version}"

  vpc_config {
    subnet_ids              = ["${module.vpc.public_subnets}", "${module.vpc.private_subnets}"]
    security_group_ids      = ["${aws_security_group.cluster.id}"]
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
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.cluster.name}"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.cluster.name}"
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
}

resource "aws_iam_instance_profile" "worker_node" {
  name = "${var.cluster_name}-${var.environment}-instance-profile"
  role = "${aws_iam_role.worker_node.name}"
}

resource "aws_iam_policy" "worker_node_autoscaler" {
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ],
    "Resource": "*"
  }
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "node-custom-policy" {
  policy_arn = "${aws_iam_policy.worker_node_autoscaler.arn}"
  role       = "${aws_iam_role.worker_node.name}"
}

#####
# EKS worker nodes cloudformatino stack
#####

resource "aws_cloudformation_stack" "worker" {
  name         = "${var.cluster_name}-${var.environment}-worker-nodes-stack"
  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]

  parameters = {
    KeyName                          = "${var.ssh_key_name}"
    NodeImageId                      = "${var.ami_id}"
    ClusterName                      = "${aws_eks_cluster.cluster.id}"
    NodeGroupName                    = "${var.cluster_name}-${var.environment}-node-group"
    NodeInstanceType                 = "${var.worker_instance_type}"
    BootstrapArguments               = "--kubelet-extra-args --node-labels=lifecycle=OnDemand"
    ClusterControlPlaneSecurityGroup = "${aws_security_group.cluster.id}"
    Subnets                          = "${join(",", module.vpc.private_subnets)}"
    VpcId                            = "${module.vpc.vpc_id}"
    NodeInstanceProfileName          = "${aws_iam_instance_profile.worker_node.name}"
    NodeInstanceRoleName             = "${aws_iam_role.worker_node.name}"
    NodeSecurityGroupName            = "${aws_security_group.node.id}"

    NodeAutoScalingGroupDesiredCapacity = "3"
    NodeAutoScalingGroupMinSize         = "1"
    NodeAutoScalingGroupMaxSize         = "20"
  }

  template_body = "${file("cfm/worker-node-stack.yaml")}"

  tags = "${var.tags}"
}
