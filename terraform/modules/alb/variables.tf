# Values the root will pass in. Public subnets = two AZs (two districts) for high availability.

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}
