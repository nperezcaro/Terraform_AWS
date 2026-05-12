module "networking" {
  source = "../../modules/networking"

  project              = var.project
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway         = var.enable_nat_gateway
  single_nat_gateway         = true
  enable_interface_endpoints = var.enable_interface_endpoints
  enable_flow_logs           = var.enable_flow_logs
}

module "ecr" {
  source  = "../../modules/ecr"
  project = var.project
  env     = var.env
  repositories = {
    api    = { scan_on_push = true, max_image_count = 5 }
    worker = { scan_on_push = true, max_image_count = 5 }
  }
}
module "s3_raw" {
  source             = "../../modules/s3"
  project            = var.project
  env                = var.env
  bucket_suffix      = "raw"
  versioning_enabled = false
  lifecycle_rules = [{
    id              = "expire-raw-90d"
    enabled         = true
    expiration_days = 90
  }]
}
module "s3_processed" {
  source             = "../../modules/s3"
  project            = var.project
  env                = var.env
  bucket_suffix      = "processed"
  versioning_enabled = true
  lifecycle_rules = [{
    id                            = "expire-noncurrent-90d"
    enabled                       = true
    noncurrent_version_expiration = 90
  }]
}
module "s3_artifacts" {
  source             = "../../modules/s3"
  project            = var.project
  env                = var.env
  bucket_suffix      = "artifacts"
  versioning_enabled = true
  lifecycle_rules = [{
    id                            = "expire-noncurrent-90d"
    enabled                       = true
    noncurrent_version_expiration = 90
  }]
}

# EC2 is declared before RDS so its SG ID can be forwarded to rds.allowed_sg_ids.
# The RDS SM read policy is attached via a standalone resource below to avoid
# a circular module dependency (EC2 <- RDS policy ARN + RDS <- EC2 SG ID).
module "ec2" {
  source                      = "../../modules/ec2"
  project                     = var.project
  env                         = var.env
  vpc_id                      = module.networking.vpc_id
  subnet_id                   = module.networking.public_subnet_ids[0]
  allowed_ssh_cidrs           = var.allowed_ssh_cidrs
  secret_recovery_window_days = 0
}