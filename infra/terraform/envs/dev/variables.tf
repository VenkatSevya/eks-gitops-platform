variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "cluster_name" {
  type    = string
  default = "shop-dev"
}

variable "github_repo" {
  description = "GitHub repository allowed to push images, as <user>/<repo>"
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Set to false if your AWS account already has the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large", "m5.large"]
}

variable "capacity_type" {
  type    = string
  default = "SPOT"
}
