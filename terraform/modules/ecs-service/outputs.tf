# What the root (and Workflow 06) may ask this service for.

output "service_name" {
  value = aws_ecs_service.app.name
}

output "service_security_group_id" {
  value = aws_security_group.service.id
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}
