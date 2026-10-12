terraform {
  required_version = ">= 1.10" # needed for S3 native state locking (use_lockfile)
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "eks-gitops-platform"
      ManagedBy = "terraform"
    }
  }
}
