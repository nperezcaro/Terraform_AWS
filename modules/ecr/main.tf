locals {
  name = "${var.project}-${var.env}"
  tags = merge(
    {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_ecr_repository" "this" {
  for_each             = var.repositories
  name                 = "${local.name}-${each.key}"
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = var.repositories
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = each.value.lifecycle_rules != null ? [
      for r in each.value.lifecycle_rules : {
        rulePriority = r.rule_priority
        description  = r.description
        selection = {
          tagStatus   = r.tag_status
          countType   = r.count_type
          countNumber = r.count_number
        }
        action = { type = "expire" }
      }
      ] : [
      {
        rulePriority = 1
        description  = "Keep last ${each.value.max_image_count} images (any tag)"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = each.value.max_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}
