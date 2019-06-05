variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

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

variable "vpc_cidr" {
  default     = "" # empty for now, needs to be removed later on
  description = "Amazon Virtual Private Cloud Classless Inter-Domain Routing range."
}

variable "private_subnets_cidrs" {
  type        = list(string)
  default     = [""] # empty for now, needs to be removed later on
  description = "Classless Inter-Domain Routing ranges for private subnets."
}

variable "public_subnets_cidrs" {
  type        = list(string)
  default     = [""] # empty for now, needs to be removed later on
  description = "Classless Inter-Domain Routing ranges for public subnets."
}

variable "tags" {
  type        = map(string)
  description = "Default tags attached to all resources."
}

variable "eks_version" {
  default = "1.12"
}

variable "ssh_key_name" {
  default = "ceng-prod"
}

variable "ami_id" {
  description = "AmazonLinux 2 AMI EKS optimised"
  default     = "ami-08716b70cac884aaa"
}

variable "hosted_zone_id" {
  description = "Hosted zone id used by bastion host."
}

variable "spot_worker_instance_type" {
}

variable "vpc_single_nat_gateway" {
  type = bool
}

variable "vpc_one_nat_gateway_per_az" {
  type = bool
}
