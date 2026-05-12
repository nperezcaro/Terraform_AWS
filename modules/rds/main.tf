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

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ── Password generation ────────────────────────────────────────────────────────
resource "random_password" "db" {
  length  = 32
  special = true
  # Exclude chars that break JDBC / SQLAlchemy connection strings and psql CLI.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ── Secrets Manager ───────────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name}/rds/master-credentials"
  description             = "Master credentials for ${local.name} RDS PostgreSQL instance."
  recovery_window_in_days = var.secret_recovery_window_days
  tags                    = merge(local.tags, { Name = "${local.name}-rds-secret" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  # Standard AWS RDS rotation JSON schema — compatible with native rotation Lambdas.
  # host is resolved after RDS is created; Terraform dependency graph handles ordering.
  secret_string = jsonencode({
    engine               = "postgres"
    host                 = aws_db_instance.this.address
    port                 = aws_db_instance.this.port
    dbname               = var.db_name
    username             = var.db_username
    password             = random_password.db.result
    dbInstanceIdentifier = aws_db_instance.this.identifier
  })

  # Prevent Terraform from overwriting the secret after external rotation.
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ── IAM policy — read this secret (attach to app task/instance roles) ─────────
data "aws_iam_policy_document" "read_db_secret" {
  statement {
    sid    = "AllowGetSecretValue"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.db.arn]
  }
}

resource "aws_iam_policy" "read_db_secret" {
  name        = "${local.name}-read-rds-secret"
  description = "Allows reading the RDS master credentials secret for ${local.name}."
  policy      = data.aws_iam_policy_document.read_db_secret.json
  tags        = local.tags
}

# ── Subnet Group ──────────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "this" {
  name        = "${local.name}-rds-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "RDS subnet group for ${local.name}."
  tags        = merge(local.tags, { Name = "${local.name}-rds-subnet-group" })
}

# ── Parameter Group ───────────────────────────────────────────────────────────
resource "aws_db_parameter_group" "this" {
  name        = "${local.name}-pg16"
  family      = "postgres16"
  description = "Custom parameter group for ${local.name}."

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = merge(local.tags, { Name = "${local.name}-pg16" })
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${local.name}-sg-rds"
  description = "Allow PostgreSQL (5432) inbound from specified SGs only."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_sg_ids
    content {
      description     = "PG from ${ingress.value}"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # No egress rules — RDS never initiates outbound connections.
  # Omitting inline egress keeps the AWS default allow-all outbound, which has no
  # practical effect for RDS. To enforce a hard deny, use separate
  # aws_security_group_rule resources (inline rules cannot express "allow nothing").

  tags = merge(local.tags, { Name = "${local.name}-sg-rds" })
}

# ── RDS Instance ──────────────────────────────────────────────────────────────
resource "aws_db_instance" "this" {
  identifier     = "${local.name}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  backup_retention_period    = var.backup_retention_period
  backup_window              = "02:00-03:00"
  maintenance_window         = "Sun:03:00-Sun:04:00"
  auto_minor_version_upgrade = true

  tags = merge(local.tags, { Name = "${local.name}-postgres" })
}
