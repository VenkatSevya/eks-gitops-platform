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
  description = "Only with use_github_oidc = true: GitHub variable AWS_ROLE_ARN"
  value       = var.use_github_oidc ? aws_iam_role.github_actions[0].arn : null
}

output "github_actions_user" {
  description = "Only with use_github_oidc = false: create an access key for this user in IAM and store it as GitHub secrets"
  value       = var.use_github_oidc ? null : aws_iam_user.github_actions[0].name
}
