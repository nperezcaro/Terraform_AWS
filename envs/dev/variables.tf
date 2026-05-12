variable "project"    { type = string }
variable "env"        { type = string }
variable "aws_region" { type = string }

variable "vpc_cidr"             { type = string }
variable "azs"                  { type = list(string) }
variable "public_subnet_cidrs"  { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }

variable "enable_nat_gateway"         { type = bool }
variable "enable_interface_endpoints" { type = bool }
variable "enable_flow_logs"           { type = bool }

variable "db_name"     { type = string }
variable "db_username" { type = string }

variable "allowed_ssh_cidrs" {
  description = "Your public IP(s) for SSH access. Run: curl ifconfig.me"
  type        = list(string)
}
