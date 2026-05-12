variable "project" { type = string }
variable "env" { type = string }

variable "vpc_id" { type = string }

variable "subnet_id" {
  description = "Public subnet ID. Instance needs a public route for EIP to work."
  type        = string
}

variable "instance_type" {
  description = "t3.micro = free tier eligible (750 hrs/month)."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Override AMI. Leave null to use latest Amazon Linux 2023 x86_64."
  type        = string
  default     = null
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH (port 22). Restrict to your IP — never 0.0.0.0/0 in prod."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_policy_arns" {
  description = "Extra IAM policy ARNs to attach to the instance role."
  type        = list(string)
  default     = []
}

variable "secret_recovery_window_days" {
  description = "SM secret recovery window in days. 0 = force-delete (dev). Use 30 for prod."
  type        = number
  default     = 0
}

variable "root_volume_size_gb" {
  description = "EBS root volume size. Free tier: up to 30 GB total across all instances."
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
