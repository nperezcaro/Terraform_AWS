locals {
  github_sub_prefix = "repo:${var.github_org}/${var.github_repo}"
}

# ── GitHub OIDC Identity Provider ─────────────────────────────────────────────
# One per AWS account
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS now verifies the GitHub OIDC certificate chain natively, so these
  # thumbprints are no longer security-critical. The field is still required
  # by the API. Any non-empty value is accepted.
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

# ── Plan role — assumable ONLY on pull_request events ─────────────────────────
data "aws_iam_policy_document" "plan_trust" {
  statement {
    sid     = "AllowGitHubActionsPlan"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Audience must be sts.amazonaws.com — enforced by aws-actions/configure-aws-credentials.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Subject claim — restricts to pull_request events from this specific repo.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.github_sub_prefix}:pull_request"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "${var.project}-gha-terraform-plan"
  description          = "GitHub Actions role for terraform plan on PRs from ${var.github_org}/${var.github_repo}"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600 # 1 hour — plan should never need longer
}

resource "aws_iam_role_policy_attachment" "plan" {
  for_each   = toset(var.plan_policy_arns)
  role       = aws_iam_role.plan.name
  policy_arn = each.value
}

# ── Apply role — assumable ONLY via the GitHub Environment ────────────────────
# The `environment:` claim is set when a workflow job specifies `environment: dev`.
# This is more secure than a branch ref because GitHub Environments support
# required reviewers, secrets isolation, and deployment branch restrictions.
data "aws_iam_policy_document" "apply_trust" {
  statement {
    sid     = "AllowGitHubActionsApply"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to jobs running under the named GitHub Environment.
    # Configure required reviewers + branch protection in GitHub Settings -> Environments.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.github_sub_prefix}:environment:${var.apply_environment}"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = "${var.project}-gha-terraform-apply"
  description          = "GitHub Actions role for terraform apply via ${var.apply_environment} environment"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "apply" {
  for_each   = toset(var.apply_policy_arns)
  role       = aws_iam_role.apply.name
  policy_arn = each.value
}
