# Values the root will pass in.

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "image_uri" {
  type        = string
  description = "ECR URI including tag, e.g. .../accelerator:latest"
}

# Empty until the root passes the ALB. Defaults let a service-only apply still work.

variable "target_group_arn" {
  type        = string
  description = "ALB target group. Empty until Workflow 06."
  default     = ""
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB SG. Empty until Workflow 06."
  default     = ""
}

