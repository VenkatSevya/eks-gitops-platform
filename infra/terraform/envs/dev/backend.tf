# State lives in the S3 bucket created by ../../bootstrap.
# scripts/configure.sh replaces 472639329900 with your AWS account ID.
terraform {
  backend "s3" {
    bucket       = "tfstate-472639329900-eks-gitops"
    key          = "dev/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true # S3 native locking, no DynamoDB table needed
  }
}
