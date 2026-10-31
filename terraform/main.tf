# =============================================================================
# AWS Graduate Cloud Skills Accelerator
# Root module — calls only.
# =============================================================================

locals {
  project = var.project
  region  = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  project = local.project
}

module "ecr" {
  source  = "./modules/ecr"
  project = local.project
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  project            = local.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "alb" {
  source = "./modules/alb"

  project           = local.project
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecs_service" {
  source = "./modules/ecs-service"

  project                = local.project
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  cluster_arn            = module.ecs_cluster.cluster_arn
  capacity_provider_name = module.ecs_cluster.capacity_provider_name
  image_uri              = "${module.ecr.repository_url}:latest"
  desired_count          = var.desired_count

  target_group_arn      = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id

  # Wait until the capacity provider is attached to the cluster.
  depends_on = [module.ecs_cluster]
}