# main.tf - Main configuration file

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }

  
  # Optionally configure a backend for state storage (e.g., S3)
  # backend "s3" {
  #   bucket = "terraform-state-recommendation-api"
  #   key    = "terraform.tfstate"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = var.aws_region
}

# Local variables
locals {
  app_name = "recommendation-collections-api"
  environment = var.environment
  tags = {
    Project     = local.app_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../modules/vpc"
  
  app_name             = local.app_name
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  tags                 = local.tags
}

# Security Groups Module
module "security_groups" {
  source = "../modules/security_groups"
  
  app_name    = local.app_name
  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags
}

# EC2 Module
module "ec2" {
  source = "../modules/ec2"
  
  app_name              = local.app_name
  environment           = local.environment
  instance_type         = var.instance_type
  key_name              = var.key_name
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_ids    = [module.security_groups.app_sg_id]
  user_data             = templatefile("${path.module}/user_data.sh", {
    app_name = local.app_name
  })
  tags                  = local.tags
}

# ALB Module
module "alb" {
  source = "../modules/alb"
  
  app_name         = local.app_name
  environment      = local.environment
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_sg_id
  target_ids       = module.ec2.instance_ids
  health_check_path = "/health"
  tags             = local.tags
}