# 1. Picture of the host. ECS-optimised Amazon Linux 2.

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# 2. Badge the EC2 host wears so the ECS agent can register and pull images.

resource "aws_iam_role" "ecs_instance" {
  name = "${var.project}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}


# 3. Lock on the host. Egress via NAT. No public HTTP.

resource "aws_security_group" "instance" {
  name        = "${var.project}-ecs-instance-sg"
  description = "ECS container instances - egress via NAT, no public HTTP"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-ecs-instance-sg"
  }
}


# 4. Named cluster. ECS uses this name. Empty until a host joins.

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"

  tags = {
    Name = "${var.project}-cluster"
  }
}


# 5. Launch template for the host, then the group that keeps one of them.

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(replace(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  EOT
  , "\r", ""))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project}-asg"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  # Off so terraform destroy can terminate the instance.
  # A live production ASG often sets this true with managed termination protection.
  protect_from_scale_in = false

  tag {
    key                 = "Name"
    value               = "${var.project}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# 6. Link the cluster to the ASG. The service will ask this provider for a seat.

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.project}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"
    managed_draining               = "DISABLED"
    # Default draining is ENABLED. That adds hook ecs-managed-draining-termination-hook.
    # terraform destroy then waits on Terminating:Wait and times out. Off for this lab.

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
    base              = 1
  }
}


