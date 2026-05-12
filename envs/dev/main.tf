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
