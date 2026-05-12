variable "project" { type = string }
variable "env" { type = string }

variable "bucket_suffix" {
  description = "Short logical suffix: 'raw', 'processed', 'artifacts', etc."
  type        = string
}

variable "versioning_enabled" {
  type    = bool
  default = false
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets. Set false for prod."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  type = list(object({
    id                            = string
    enabled                       = bool
    expiration_days               = optional(number, null)
    noncurrent_version_expiration = optional(number, null)
    transition_days               = optional(number, null)
    transition_storage_class      = optional(string, null)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
