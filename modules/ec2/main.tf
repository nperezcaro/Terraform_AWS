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

# ── AMI — latest Amazon Linux 2023 x86_64 ────────────────────────────────────
# AL2023: ships Python 3.9+, SSM agent, cloud-init, ec2-user account.
# Everything Ansible needs is present out of the box.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── SSH Key Pair ───────────────────────────────────────────────────────────────
# Terraform generates the key. Private key is stored in TF state (sensitive = true)
# AND in Secrets Manager. Always retrieve from SM — don't rely on state for daily use.
resource "tls_private_key" "ec2" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "ec2" {
  key_name   = "${local.name}-ec2-key"
  public_key = tls_private_key.ec2.public_key_openssh
  tags       = merge(local.tags, { Name = "${local.name}-ec2-key" })
}

resource "aws_secretsmanager_secret" "ssh_key" {
  name                    = "${local.name}/ec2/ssh-private-key"
  description             = "ED25519 private key for ${local.name} EC2 instance."
  recovery_window_in_days = var.secret_recovery_window_days
  tags                    = merge(local.tags, { Name = "${local.name}-ec2-key-secret" })
}

resource "aws_secretsmanager_secret_version" "ssh_key" {
  secret_id     = aws_secretsmanager_secret.ssh_key.id
  secret_string = tls_private_key.ec2.private_key_openssh
}

# ── IAM Role + Instance Profile ───────────────────────────────────────────────
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name}-ec2-role"
  description        = "Instance role for ${local.name} EC2."
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.tags
}

# SSM Session Manager — free alternative to SSH for debugging; no port 22 required.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Caller-supplied policies (e.g. SM read policy from the RDS module).
# Wired from envs/dev/main.tf to avoid circular module dependency.
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.ec2.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2.name
  tags = local.tags
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "${local.name}-sg-ec2"
  description = "EC2 instance SG - SSH inbound, all outbound."
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "All outbound (RDS port 5432, SM/ECR port 443 via NAT, updates)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-ec2" })
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "this" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.al2023.id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = aws_key_pair.ec2.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only — blocks SSRF attacks
    http_put_response_hop_limit = 1
  }

  tags = merge(local.tags, { Name = "${local.name}-ec2" })
}

# ── Elastic IP — stable address for Ansible inventory ─────────────────────────
# Free while attached to a running instance.
# Costs ~$0.005/hr when the instance is stopped — destroy dev infra when not in use.
resource "aws_eip" "ec2" {
  domain   = "vpc"
  instance = aws_instance.this.id
  tags     = merge(local.tags, { Name = "${local.name}-ec2-eip" })
}
