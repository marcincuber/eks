#####
# VPC configuration for EKS
#####

# lock down default security group
resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-default-sg"
    }
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.33.0"

  name = "${local.name_prefix}-vpc"

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
    "kubernetes.io/role/internal-elb" = "1",
    "mapPublicIpOnLaunch"             = "FALSE"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1",
    "mapPublicIpOnLaunch"    = "TRUE"
  }


  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    },
  )

  # VPC Endpoint for ECR DKR
  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.vpc_endpoint.id]

  # VPC endpoint for S3
  enable_s3_endpoint = true
}

#####
# Security Group configuration for VPC endpoints
#####

resource "random_id" "vpc_endpoint_sg_suffix" {
  byte_length = 4
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "${local.name_prefix}-vpc-endpoint-sg-${random_id.vpc_endpoint_sg_suffix.hex}"
  description = "Security Group used by VPC Endpoints."
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = "${local.name_prefix}-vpc-endpoint-sg-${random_id.vpc_endpoint_sg_suffix.hex}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "vpc_endpoint_egress" {
  security_group_id = aws_security_group.vpc_endpoint.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "vpc_endpoint_self_ingress" {
  security_group_id        = aws_security_group.vpc_endpoint.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.vpc_endpoint.id
}

#####
# VPC Flow logs
#####

module "vpc-flow-logs" {
  source  = "umotif-public/vpc-flow-logs/aws"
  version = "~> 1.0.1"

  name_prefix = "${local.name_prefix}"
  vpc_id      = module.vpc.vpc_id

  traffic_type = "ALL"

  tags = var.tags
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

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
