variable "aws_role_arn" {
  type = string
}

variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region in which resources will get deployed. Defaults to Ireland."
}

variable "tags" {
  type        = map(string)
  description = "Default tags attached to all resources."
  default     = {}
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes cluster name"
}

variable "git_repository_branch" {
  description = "Branch to use as the upstream GitOps reference"
  type        = string
  default     = "master"
}

variable "flux_docker_tag" {
  description = "Tag of flux Docker image to pull"
  type        = string
  default     = "1.21.1"
}

variable "flux_known_hosts" {
  description = "Set of hosts and their public ssh keys to mount into `/root/.ssh/known_hosts`"
  type        = set(string)
  default     = []
}

variable "flux_args_extra" {
  description = "Mapping of additional arguments to provide to the flux daemon"
  type        = map(string)
  default     = {}
}

variable "git_url" {
  type        = string
  description = "Git URL used by flux"
}

variable "git_path" {
  type        = string
  description = "Git path used by flux"
}

variable "aws_partition" {
  type    = string
  default = "public"

  description = "A Partition is a group of AWS Region and Service objects. You can use a partition to determine what services are available in a region, or what regions a service is available in."

  validation {
    condition     = contains(["public", "china"], var.aws_partition)
    error_message = "Argument \"aws_partition\" must be either \"public\" or \"china\"."
  }
}
