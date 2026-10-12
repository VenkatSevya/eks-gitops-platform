locals {
  services = ["shop-api", "shop-worker", "shop-frontend"]
}

module "vpc" {
  source = "../../modules/vpc"
  name   = var.cluster_name
}

module "eks" {
  source              = "../../modules/eks"
  cluster_name        = var.cluster_name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  capacity_type       = var.capacity_type
}

module "ecr" {
  source       = "../../modules/ecr"
  repositories = local.services
}
