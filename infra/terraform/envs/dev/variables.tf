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


variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large", "m5.large"]
}

variable "capacity_type" {
  type    = string
  default = "SPOT"
}

variable "use_github_oidc" {
  description = "true = GitHub Actions logs in with OIDC (best). false = an IAM user with access keys, for accounts whose policy blocks creating OIDC providers"
  type        = bool
  default     = false
}
