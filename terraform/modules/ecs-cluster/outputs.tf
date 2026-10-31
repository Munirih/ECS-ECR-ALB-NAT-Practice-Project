# What the root (and the service module) may ask this cluster for.

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.this.name
  # Service must not start until this provider is attached to the cluster.
  depends_on = [aws_ecs_cluster_capacity_providers.this]
}
