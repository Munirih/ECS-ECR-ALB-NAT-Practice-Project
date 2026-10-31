# 1. Lock on the task. Egress only until Workflow 06 adds the ALB rule.

resource "aws_security_group" "service" {
  name        = "${var.project}-svc-sg"
  description = "ECS tasks - egress only until the ALB rule is added"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-svc-sg"
  }
}


# 2. Badge ECS uses to pull the image and start the container.

resource "aws_iam_role" "execution" {
  name = "${var.project}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# 3. Instruction sheet. Image, size, port 80. Not a running task yet.

resource "aws_ecs_task_definition" "app" {
  family                   = var.project
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution.arn
  cpu                      = "256"
  memory                   = "256"

  container_definitions = jsonencode([
    {
      name      = var.project
      image     = var.image_uri
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}


# 4. Standing order: always one task. Private subnets. No public IP.

resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  # terraform destroy waits 20 min for INACTIVE if the service stays DRAINING.
  # Force skip that wait. Off and destroy times out.
  force_delete = true

  # One t3.micro + awsvpc: two ENIs (host + one task). Default 200/100 tries a second
  # task and stalls in PROVISIONING. 100/0 = stop old, then start new.
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project
    container_port   = 80
  }

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  # CodePipeline (Workflow 08) registers a new task definition.
  # Do not let a later terraform apply roll the service back.
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# 5. Inbound 80 on the task lock. Source = ALB SG only. Lab 6.5 always passes the id.

resource "aws_security_group_rule" "alb_http_in" {
  type                     = "ingress"
  description              = "HTTP from the ALB only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.service.id
  source_security_group_id = var.alb_security_group_id
}
