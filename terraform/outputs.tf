# What this root can print. Workflow 02 adds VPC ids here.

output "project" {
  value = var.project
}

output "aws_region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  value = module.vpc.nat_gateway_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "ecs_instance_security_group_id" {
  value = module.ecs_cluster.instance_security_group_id
}

output "ecs_service_name" {
  value = module.ecs_service.service_name
}

output "ecs_service_security_group_id" {
  value = module.ecs_service.service_security_group_id
}

output "app_url" {
  description = "Open with http — not https"
  value       = "http://${module.alb.alb_dns_name}"
}

output "pipeline_name" {
  value = module.cicd.pipeline_name
}



