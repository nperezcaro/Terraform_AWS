variable "project" { type = string }
variable "env" { type = string }

variable "repositories" {
  description = "Map of repositories to create. Key becomes part of the repo name."
  type = map(object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    max_image_count      = optional(number, 10)
    lifecycle_rules = optional(list(object({
      rule_priority = number
      description   = string
      tag_status    = string
      count_type    = string
      count_number  = number
    })), null)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
