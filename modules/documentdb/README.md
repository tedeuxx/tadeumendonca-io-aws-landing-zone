# AWS DocumentDB Terraform Module

Terraform module which creates AWS DocumentDB (MongoDB-compatible) resources.

## Usage

### Basic Usage

```hcl
module "documentdb" {
  source = "./modules/documentdb"

  cluster_identifier = "my-docdb-cluster"
  master_username    = "docdb"
  
  # Network configuration
  subnet_ids             = ["subnet-12345678", "subnet-87654321"]
  vpc_security_group_ids = ["sg-12345678"]
  
  # Instance configuration
  instances = {
    1 = {
      instance_class = "db.t3.medium"
    }
    2 = {
      instance_class = "db.t3.medium"
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Production Configuration

```hcl
module "documentdb_production" {
  source = "./modules/documentdb"

  cluster_identifier = "production-docdb"
  engine_version     = "4.0.0"
  master_username    = "docdb"
  
  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.documentdb.id]
  
  # Multi-AZ deployment with 2 instances
  instances = {
    1 = {
      identifier     = "production-docdb-1"
      instance_class = "db.r5.large"
    }
    2 = {
      identifier     = "production-docdb-2"
      instance_class = "db.r5.large"
    }
  }

  # Backup and maintenance
  backup_retention_period      = 7
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"
  deletion_protection          = true
  
  # Encryption
  storage_encrypted = true
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
  
  # Parameter group
  create_db_cluster_parameter_group = true
  db_cluster_parameter_group_name   = "production-docdb-params"
  db_cluster_parameter_group_family = "docdb4.0"
  
  tags = {
    Environment = "production"
    Project     = "my-project"
    Terraform   = "true"
  }
}
```

### Staging Configuration (Cost-Optimized)

```hcl
module "documentdb_staging" {
  source = "./modules/documentdb"

  cluster_identifier = "staging-docdb"
  master_username    = "docdb"
  
  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.documentdb.id]
  
  # Single instance for cost optimization
  instances = {
    1 = {
      identifier     = "staging-docdb-1"
      instance_class = "db.t3.medium"
    }
  }

  # Reduced backup retention for staging
  backup_retention_period = 3
  deletion_protection     = false
  skip_final_snapshot     = true
  
  tags = {
    Environment = "staging"
    Project     = "my-project"
    Terraform   = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_docdb_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster) | resource |
| [aws_docdb_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster_instance) | resource |
| [aws_docdb_cluster_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster_parameter_group) | resource |
| [aws_docdb_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_subnet_group) | resource |
| [random_password.master_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_identifier"></a> [cluster\_identifier](#input\_cluster\_identifier) | The cluster identifier. If omitted, Terraform will assign a random, unique identifier | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The database engine version. Updating this argument results in an outage | `string` | `"4.0.0"` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Username for the master DB user | `string` | `"docdb"` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file. If not provided, a random password will be generated | `string` | `null` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `true` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of VPC subnet IDs | `list(string)` | `[]` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate with the Cluster | `list(string)` | `[]` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Map of cluster instances and any specific/overriding attributes to be created | `any` | `{}` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance class to use. For details on CPU and memory, see Scaling for DocumentDB instances | `string` | `"db.t3.medium"` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for | `number` | `7` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB cluster is encrypted | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | A value that indicates whether the DB cluster has deletion protection enabled | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | Amazon Resource Name (ARN) of cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for the DocumentDB cluster |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | A read-only endpoint for the DocumentDB cluster, automatically load-balanced across replicas |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The DocumentDB cluster identifier |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | The database port |
| <a name="output_cluster_master_username"></a> [cluster\_master\_username](#output\_cluster\_master\_username) | The master username for the cluster |

## Examples

See the [examples](examples/) directory for working examples to reference:

- [Complete](examples/complete) - Complete DocumentDB cluster with all features
- [Simple](examples/simple) - Simple DocumentDB cluster for development

## Authors

Module is maintained by the [terraform-aws-modules community](https://github.com/terraform-aws-modules).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/terraform-aws-modules/terraform-aws-documentdb/tree/master/LICENSE) for full details.