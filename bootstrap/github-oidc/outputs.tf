output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "terraform_plan_role_arn" {
  description = "Set as GitHub secret: AWS_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "terraform_apply_role_arn" {
  description = "Set as GitHub secret: AWS_APPLY_ROLE_ARN"
  value       = aws_iam_role.apply.arn
}

output "github_secrets_to_set" {
  description = "Run these commands or set via the GitHub UI."
  value = {
    AWS_PLAN_ROLE_ARN  = aws_iam_role.plan.arn
    AWS_APPLY_ROLE_ARN = aws_iam_role.apply.arn
  }
}
