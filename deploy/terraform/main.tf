terraform {
  required_version = "~> 0.11.13"
}

provider "aws" {
  region = "eu-west-1"
}

#####
# VPC configuration for EKS
#####

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.60.0"

  name = "my-eks-test-vpc"

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

  tags = {
    Terraform                                   = "true"
    Environment                                 = "test"
    "kubernetes.io/cluster/my-eks-test-cluster" = "shared"
  }
}

#####
# EKS Control Plane security group
#####

resource "aws_security_group" "cluster" {
  name        = "terraform-eks-cluster"
  description = "Control Plane SG- Cluster communication with worker nodes"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name                                        = "eks-test-cluster-control-plane"
    Terraform                                   = "true"
    Environment                                 = "test"
    "kubernetes.io/cluster/my-eks-test-cluster" = "owned"
  }
}

################################
resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster.id}"
  source_security_group_id = "${aws_security_group.node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
  cidr_blocks       = ["143.252.0.0/16"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.cluster.id}"
  to_port           = 443
  type              = "ingress"
}

# EKS Worker Nodes Resources
# EC2 Security Group to allow networking traffic

resource "aws_security_group" "node" {
  name        = "terraform-eks-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-${terraform.workspace}",
     "kubernetes.io/cluster/my-eks-test-cluster", "owned",
    )
  }"
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

##########################################
#####
# EKS Cluster
#####
resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  name                      = "my-eks-test-cluster"
  role_arn                  = "${aws_iam_role.cluster.arn}"
  version                   = "1.12"

  vpc_config {
    subnet_ids              = ["${module.vpc.public_subnets}", "${module.vpc.private_subnets}"]
    security_group_ids      = ["${aws_security_group.cluster.id}"]
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
  }
}

resource "aws_iam_role" "cluster" {
  name = "terraform-eks-cluster-role-test"

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
  name = "terraform-eks-node"

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

resource "aws_iam_policy" "worker_nodes_policy" {
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
  policy_arn = "${aws_iam_policy.worker_nodes_policy.arn}"
  role       = "${aws_iam_role.worker_node.name}"
}

resource "aws_iam_instance_profile" "worker_node" {
  name = "terraform-eks-node-instance-profile"
  role = "${aws_iam_role.worker_node.name}"
}

#####
# EKS worker nodes cloudformatino stack
#####

resource "aws_cloudformation_stack" "falcon" {
  name         = "my-eks-test-worker-nodes-stack"
  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]

  parameters = {
    KeyName                          = "ceng-test"
    NodeImageId                      = "ami-08716b70cac884aaa"
    ClusterName                      = "my-eks-test-cluster"
    NodeGroupName                    = "my-eks-test-cluster-node-group"
    ClusterControlPlaneSecurityGroup = "${aws_security_group.cluster.id}"
    Subnets                          = "${join(",", module.vpc.private_subnets)}"
    VpcId                            = "${module.vpc.vpc_id}"
    NodeInstanceProfileName          = "${aws_iam_instance_profile.worker_node.name}"
    NodeInstanceRoleName             = "${aws_iam_role.worker_node.name}"
    NodeSecurityGroupName            = "${aws_security_group.node.id}"
  }

  template_body = "${file("cfm/worker-node-stack.yaml")}"

  tags {
    name = "eks-test"
  }
}
