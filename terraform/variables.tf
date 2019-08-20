variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region in which resources will get deployed. Defaults to Ireland."
}

variable "availability_zones" {
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  description = "Availability zones for the default Ireland region."
}

variable "bastion_instance_types" {
  type        = list(string)
  description = "Bastion instance types used for spot instances."
  default     = ["t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large", "t2.nano", "t2.micro", "t2.small", "t2.medium", "t2.large"]
}

variable "worker_instance_types" {
  type        = string
  description = "Worker instance types used for spot instances."
  default     = "m5.4xlarge,m5d.4xlarge,m5a.4xlarge,m5ad.4xlarge,m4.4xlarge"
}

variable "vpc_cidr" {
  description = "Amazon Virtual Private Cloud Classless Inter-Domain Routing range."
}

variable "private_subnets_cidrs" {
  type        = list(string)
  description = "Classless Inter-Domain Routing ranges for private subnets."
}

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "Classless Inter-Domain Routing ranges for public subnets."
}

variable "tags" {
  type        = map(string)
  description = "Default tags attached to all resources."
  default = {
    ServiceType = "ceng-eks"
  }
}

variable "eks_version" {}

variable "ssh_key_name" {
  default = "ceng-prod"
}

variable "ami_id" {
  description = "AmazonLinux 2 AMI EKS optimised"
  default     = "ami-0199284372364b02a"
}

variable "hosted_zone_id" {
  description = "Hosted zone id used by bastion host."
}

variable "worker_instance_type" {
  default = ""
}

variable "spot_worker_instance_type" {
  default = "m5.4xlarge"
}

variable "vpc_single_nat_gateway" {
  type = bool
}

variable "vpc_one_nat_gateway_per_az" {
  type = bool
}

variable "ondemand_number_of_nodes" {
  type = number
}

variable "ondemand_percentage_above_base" {
  type = number
}

variable "spot_instance_pools" {
  type = number
}

variable "desired_number_worker_nodes" {
  type = number
}

variable "min_number_worker_nodes" {
  type = number
}

variable "max_number_worker_nodes" {
  type = number
}

variable "assume_role_arn" {
  type = string
}
