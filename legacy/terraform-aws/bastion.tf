module "bastion" {
  source  = "umotif-public/bastion/aws"
  version = "~> 2.0.3"

  name_prefix = local.name_prefix

  aws_partition = var.aws_partition

  vpc_id         = module.vpc.vpc_id
  public_subnets = flatten(module.vpc.public_subnets)

  hosted_zone_id = var.hosted_zone_id
  ssh_key_name   = var.ssh_key_name

  tags = var.tags
}

output "bastion_security_group_id" {
  value = module.bastion.security_group_id
}
