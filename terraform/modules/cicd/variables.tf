# Values the root will pass in.

variable "project" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "codestar_connection_arn" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "ecr_repository_url" {
  type        = string
  description = "Full URL without tag"
}

variable "ecr_repository_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}
