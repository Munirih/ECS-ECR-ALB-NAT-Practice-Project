# 1. Private registry in this account, in this region.
# Not a room of the VPC. ECS later pulls accelerator:latest from here — not from your laptop.

resource "aws_ecr_repository" "this" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = var.project
  }
}
