################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = aws_docdb_cluster.this.arn
}

output "cluster_id" {
  description = "The DocumentDB cluster identifier"
  value       = aws_docdb_cluster.this.id
}

output "cluster_identifier" {
  description = "The DocumentDB cluster identifier"
  value       = aws_docdb_cluster.this.cluster_identifier
}

output "cluster_resource_id" {
  description = "The DocumentDB Cluster Resource ID"
  value       = aws_docdb_cluster.this.cluster_resource_id
}

output "cluster_endpoint" {
  description = "Endpoint for the DocumentDB cluster"
  value       = aws_docdb_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "A read-only endpoint for the DocumentDB cluster, automatically load-balanced across replicas"
  value       = aws_docdb_cluster.this.reader_endpoint
}

output "cluster_hosted_zone_id" {
  description = "The Route53 Hosted Zone ID of the endpoint"
  value       = aws_docdb_cluster.this.hosted_zone_id
}

output "cluster_port" {
  description = "The database port"
  value       = aws_docdb_cluster.this.port
}

output "cluster_master_username" {
  description = "The master username for the cluster"
  value       = aws_docdb_cluster.this.master_username
  sensitive   = true
}

output "cluster_master_user_secret" {
  description = "The generated database password when `manage_master_user_password` is set to `true`"
  value       = aws_docdb_cluster.this.master_user_secret
  sensitive   = true
}

################################################################################
# Cluster Parameter Group
################################################################################

output "cluster_parameter_group_arn" {
  description = "The ARN of the DocumentDB cluster parameter group"
  value       = try(aws_docdb_cluster_parameter_group.this[0].arn, null)
}

output "cluster_parameter_group_id" {
  description = "The DocumentDB cluster parameter group name"
  value       = try(aws_docdb_cluster_parameter_group.this[0].id, null)
}

################################################################################
# Subnet Group
################################################################################

output "subnet_group_arn" {
  description = "The ARN of the DocumentDB subnet group"
  value       = try(aws_docdb_subnet_group.this[0].arn, null)
}

output "subnet_group_id" {
  description = "The DocumentDB subnet group name"
  value       = try(aws_docdb_subnet_group.this[0].id, null)
}

################################################################################
# Cluster Instance(s)
################################################################################

output "cluster_instances" {
  description = "A map of cluster instances and their attributes"
  value       = aws_docdb_cluster_instance.this
  sensitive   = true
}