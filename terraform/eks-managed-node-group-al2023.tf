#####
# Launch Template with AL2023 AMI
#####
resource "aws_launch_template" "cluster_al2023" {
  name = "${var.name_prefix}-node-group-launch-template-al2023"

  image_id               = data.aws_ssm_parameter.eks_al2023.value
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = var.ebs_delete_on_termination
      encrypted             = var.ebs_encrypted
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name_prefix}-worker-node"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
    http_put_response_hop_limit = 2 # required by aws-load-balancer controller
  }

  user_data = base64encode(templatefile("userdata_al2023.tpl", {
    CLUSTER_NAME         = aws_eks_cluster.cluster.name,
    B64_CLUSTER_CA       = aws_eks_cluster.cluster.certificate_authority[0].data,
    API_SERVER_URL       = aws_eks_cluster.cluster.endpoint,
    CLUSTER_SERVICE_CIDR = var.eks_service_ipv4_cidr
  }))
}

#####
# EKS AL2023 Node Group
#####
module "eks_node_group_al2023" {
  source  = "native-cube/eks-node-group/aws"
  version = "~> 1.1.0"

  node_group_name_prefix = "${var.name_prefix}-node-group-al2023-"

  cluster_name = aws_eks_cluster.cluster.id

  create_iam_role = false
  node_role_arn   = aws_iam_role.eks_node_group.arn

  instance_types = var.instance_types

  subnet_ids = module.vpc_eks.private_subnets

  desired_size = 3
  min_size     = 3
  max_size     = 4

  labels = {
    "workload"   = "system-critical"
    "ami-family" = "AL2023"
  }

  update_config = {
    max_unavailable = 1
  }

  launch_template = {
    name    = aws_launch_template.cluster_al2023.name
    version = aws_launch_template.cluster_al2023.latest_version
  }

  capacity_type = "ON_DEMAND"

  tags = {
    "kubernetes.io/cluster/${var.name_prefix}" = "owned"
  }

  create_before_destroy = true
}

#####
# Worker IAM Role
#####
resource "aws_iam_role" "eks_node_group" {
  name = "${var.name_prefix}-node-group"

  assume_role_policy = data.aws_iam_policy_document.eks_node_group_assume_role_policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "eks_node_group" {
  role_name = aws_iam_role.eks_node_group.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/CloudWatchApplicationInsightsFullAccess"
  ]
}

resource "aws_iam_role_policy" "eks_node_group" {
  name   = "custom-policy"
  role   = aws_iam_role.eks_node_group.id
  policy = data.aws_iam_policy_document.eks_node_custom_inline_policy.json
}

#####
# Worker Security Group rules
#####
resource "aws_vpc_security_group_ingress_rule" "cluster_to_nodes" {
  security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description       = "Allow controlplane to communicate with worker nodes."

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_from_coredns_to_cluster_nodes" {
  security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description       = "All traffic from CoreDNS."

  referenced_security_group_id = aws_security_group.core_dns.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "cluster_to_karpenter_nodes" {
  security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description       = "Allow manager worker nodes and cluster all outbound to karpenter nodes."

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id
}

# Access to vpc endpoint sg
resource "aws_vpc_security_group_ingress_rule" "cluster_to_vpc_endpoints" {
  security_group_id = aws_security_group.eks_vpc_endpoint.id
  description       = "Allow EKS controlplane and nodes access to VPC endpoints."

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}
