#####
# VPC configuration for EKS
#####

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.9.0"

  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-vpc"

  azs = var.availability_zones

  cidr            = var.vpc_cidr
  private_subnets = var.private_subnets_cidrs
  public_subnets  = var.public_subnets_cidrs

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
      "kubernetes.io/cluster/${var.tags["ServiceType"]}-${var.tags["Environment"]}" = "shared"
    },
  )

  # VPC Endpoint for ECR API
  enable_ecr_api_endpoint              = true
  ecr_api_endpoint_private_dns_enabled = true
  ecr_api_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for ECR DKR
  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC endpoint for S3
  enable_s3_endpoint = false

  # VPC endpoint for DynamoDB
  enable_dynamodb_endpoint = false

}

/*
  VPC Flow logs
*/
resource "aws_cloudwatch_log_group" "flow_logs" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-vpc-flow-logs-cw-group"

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-vpc-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_flow_log" "flow_logs" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_logs.arn
  vpc_id               = module.vpc.vpc_id
  traffic_type         = "ALL"
}

resource "aws_iam_policy" "flow_logs" {
  name   = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-flow-logs-policy"
  policy = templatefile("policies/vpc_flow_logs_policy.json", {})
}

resource "aws_iam_role_policy_attachment" "flow_logs" {
  policy_arn = aws_iam_policy.flow_logs.arn
  role       = aws_iam_role.flow_logs.name
}

#####
# EKS Control Plane security group
#####

resource "aws_security_group" "cluster" {
  name        = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-control-plane-sg"
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
      "kubernetes.io/cluster/${var.tags["ServiceType"]}-${var.tags["Environment"]}" = "owned"
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
  name        = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-worker-node-sg"
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
      "kubernetes.io/cluster/${var.tags["ServiceType"]}-${var.tags["Environment"]}" = "owned"
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
  name                      = "${var.tags["ServiceType"]}-${var.tags["Environment"]}"
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
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-cluster-role"

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
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

#####
# Outputs
#####

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "eks_cluster_name" {
  value = aws_eks_cluster.cluster.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_platform_version" {
  value = aws_eks_cluster.cluster.platform_version
}

output "eks_cluster_kubernetes_version" {
  value = aws_eks_cluster.cluster.version
}

output "eks_cluster_vpc_config" {
  value = aws_eks_cluster.cluster.vpc_config.0.vpc_id
}

output "cluster_role_arn" {
  value = aws_iam_role.cluster.arn
}
