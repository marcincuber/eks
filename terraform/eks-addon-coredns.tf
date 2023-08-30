#####
# CoreDNS Security Group
#####
resource "aws_security_group" "core_dns" {
  name_prefix = "${var.name_prefix}-coredns-sg-"
  description = "EKS CoreDNS security group."

  vpc_id = module.vpc_eks.vpc_id

  tags = {
    "Name"                                     = "${var.name_prefix}-coredns-sg"
    "kubernetes.io/cluster/${var.name_prefix}" = "owned"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "all_allow_access_from_control_plane_to_core_dns" {
  security_group_id = aws_security_group.core_dns.id
  description       = "Allow communication from control plan to CoreDNS security group."

  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "all_allow_access_from_karpenter_nodes_to_core_dns" {
  security_group_id = aws_security_group.core_dns.id
  description       = "Allow communication from karpenter nodes to CoreDNS security group."

  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "core_dns_udp" {
  security_group_id = aws_security_group.core_dns.id
  description       = "Allow udp egress."

  from_port   = "53"
  to_port     = "53"
  ip_protocol = "udp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "core_dns_tcp" {
  security_group_id = aws_security_group.core_dns.id
  description       = "Allow udp egress."

  from_port   = "53"
  to_port     = "53"
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}
