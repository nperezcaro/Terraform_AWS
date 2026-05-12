variable "project" {
  description = "Project name used in IAM role names."
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_org" {
  description = "GitHub organization or username (case sensitive)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (case sensitive)."
  type        = string
}

variable "apply_environment" {
  description = "GitHub Environment name that gates apply runs. Must match `environment:` in tf-apply.yml."
  type        = string
  default     = "dev"
}

variable "plan_policy_arns" {
  description = "IAM policies attached to the plan role. ReadOnlyAccess is usually enough — terraform plan only reads."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

variable "apply_policy_arns" {
  description = "IAM policies attached to the apply role. Use AdministratorAccess to start; scope down later."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
