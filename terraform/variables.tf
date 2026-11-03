# Values this Accelerator uses. Defaults match the labs.

variable "project" {
  description = "Name prefix for all accelerator resources"
  type        = string
  default     = "accelerator"
}

variable "aws_region" {
  description = "AWS region — this Accelerator is us-east-1 only"
  type        = string
  default     = "us-east-1"
}

# Pipeline Source. ARN from Lab 8.2. Repo from git in Lab 8.1.

variable "codestar_connection_arn" {
  type        = string
  description = "ARN of the Available GitHub connection from Lab 8.2"
}

variable "github_repository" {
  type        = string
  description = "GitHub owner/repo, e.g. myuser/accelerator"
}

variable "github_branch" {
  type    = string
  default = "main"
}
