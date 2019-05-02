variable "cluster_name" {
  type = "string"
}

variable "environment" {
  type    = "string"
  default = "test"
}

variable "region" {
  type    = "string"
  default = "eu-west-1"
}

variable "tags" {
  type = "map"
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

variable "worker_instance_type" {}
