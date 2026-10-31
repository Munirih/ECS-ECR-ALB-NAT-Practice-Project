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

variable "desired_count" {
  description = "Number of ECS tasks to maintain"
  type        = number
  default     = 1
}
