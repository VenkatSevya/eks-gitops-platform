output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubernetes_version" {
  value = module.eks.cluster_version
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repositories" {
  value = module.ecr.repository_urls
}

output "github_actions_role_arn" {
  description = "Put this in GitHub: Settings > Secrets and variables > Actions > Variables > AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
