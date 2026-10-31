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
