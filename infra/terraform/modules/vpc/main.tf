data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16"

  name = var.name
  cidr = var.cidr
  azs  = local.azs

  # 2 private subnets (/20) for the nodes, 2 public subnets (/24) for the NAT gateway and load balancers
  private_subnets = [for i, az in local.azs : cidrsubnet(var.cidr, 4, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.cidr, 8, 48 + i)]

  enable_nat_gateway   = true
  single_nat_gateway   = true # one NAT gateway instead of one per AZ: cheaper, fine for a demo
  enable_dns_hostnames = true

  # Tags that let Kubernetes find the right subnets for load balancers
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}
