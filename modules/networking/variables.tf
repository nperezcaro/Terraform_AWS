variable "project" {
  description = "Project name prefix for all resource names."
  type        = string
}

variable "env" {
  description = "Environment (dev | staging | prod)."
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "List of AZs. Minimum 2 required."
  type        = list(string)
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least 2 AZs."
  }
}

variable "public_subnet_cidrs" {
  description = "One CIDR per AZ for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ for private subnets."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s). NOT free tier."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "One shared NAT GW instead of one per AZ. Cheaper, not HA."
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Create Interface Endpoints (ECR, SSM, Secrets Manager, etc.). NOT free tier."
  type        = bool
  default     = false
}

variable "interface_endpoint_services" {
  description = "Service suffixes for Interface Endpoints."
  type        = list(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "sts",
    "logs",
    "kms",
  ]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to S3."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "S3 lifecycle expiry for flow log objects."
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
