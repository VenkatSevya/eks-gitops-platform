# How GitHub Actions logs in to AWS to push images.
#
# Preferred: OIDC. GitHub gets short-lived tokens, no keys are stored anywhere.
# This AWS account's service control policy blocks iam:CreateOpenIDConnectProvider,
# so by default (use_github_oidc = false) we fall back to an IAM user whose ONLY
# permission is pushing to the three ECR repositories. Its access key is created
# by hand in the console and stored as a GitHub secret.

# ---- ECR push permissions (used by either option) ----
data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = module.ecr.repository_arns
  }
}

# ---- Option A: OIDC (use_github_oidc = true) ----
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.use_github_oidc ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

data "aws_iam_policy_document" "github_trust" {
  count = var.use_github_oidc ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count              = var.use_github_oidc ? 1 : 0
  name               = "${var.cluster_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_trust[0].json
}

resource "aws_iam_role_policy" "github_actions" {
  count  = var.use_github_oidc ? 1 : 0
  name   = "push-to-ecr"
  role   = aws_iam_role.github_actions[0].id
  policy = data.aws_iam_policy_document.ecr_push.json
}

# ---- Option B: IAM user that can only push to ECR (default) ----
resource "aws_iam_user" "github_actions" {
  count = var.use_github_oidc ? 0 : 1
  name  = "${var.cluster_name}-github-actions"
}

resource "aws_iam_user_policy" "github_actions" {
  count  = var.use_github_oidc ? 0 : 1
  name   = "push-to-ecr"
  user   = aws_iam_user.github_actions[0].name
  policy = data.aws_iam_policy_document.ecr_push.json
}
