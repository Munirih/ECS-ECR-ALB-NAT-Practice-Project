# Talk to AWS in N. Virginia (us-east-1) only.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Accelerator = "aws-graduate-cloud-skills-accelerator"
    }
  }
}
