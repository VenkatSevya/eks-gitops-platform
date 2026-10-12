module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name = var.cluster_name
  # null = the current EKS default version, which is always in standard support
  # (versions in extended support cost 6x more per hour).
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access           = true # so kubectl works from your laptop
  enable_cluster_creator_admin_permissions = true # your IAM identity becomes cluster admin

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Control-plane logs go to CloudWatch and cost money per GB; turned off for this demo.
  # In production you would keep at least "audit" and "api".
  cluster_enabled_log_types   = []
  create_cloudwatch_log_group = false

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    # Lets pods get AWS permissions through EKS Pod Identity (no stored keys)
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.capacity_type # SPOT is ~60-70% cheaper; AWS may reclaim a node at short notice

      min_size     = 1
      max_size     = 3
      desired_size = var.node_count
    }
  }
}
