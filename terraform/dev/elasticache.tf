locals {
  redis_node_count       = 1
  redis_goapp_node_count = 2
}

# ElactiCache Cluster
resource "aws_elasticache_replication_group" "dev" {
  # general
  replication_group_id       = "${local.sig}-redis-cluster"
  description                = "Managed by Terraform"
  engine                     = "redis"
  engine_version             = "7.0"
  parameter_group_name       = "default.redis7"
  node_type                  = "cache.t3.micro"
  port                       = 6379

  # scaling
  num_cache_clusters         = local.redis_node_count # if multi-az is enabled, the value of this parameter must be at least 2.
  automatic_failover_enabled = local.redis_node_count == 1 ? false : true

  # availability
  subnet_group_name          = aws_elasticache_subnet_group.dev.name
  multi_az_enabled           = false
  snapshot_window            = "19:00-20:00"
  snapshot_retention_limit   = 5
  data_tiering_enabled       = false # This parameter must be set to true when using the r6gd node.

  # maintenance
  maintenance_window         = "tue:13:30-tue:14:30"
  auto_minor_version_upgrade = "true" # Set to false for prod environment

  # security
  security_group_ids         = [aws_security_group.dev-redis.id]
  tags                       = local.default_tags
}

# Security Group for ElactCache
resource "aws_security_group" "dev-redis" {
  vpc_id = aws_vpc.dev.id
  name   = "${local.sig}-redis-tf-sg"

  ingress{
    description      = "from external server"
    from_port        = 6379
    to_port          = 6379
    protocol         = "TCP"
    security_groups  = [
      aws_security_group.dev-ec2-tf.id,
      aws_security_group.dev-eks-tf.id
    ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.default_tags
}

# Subnet Group
resource "aws_elasticache_subnet_group" "dev" {
  name = "${local.sig}-redis-subnet-group"
  description = "Managed by Terraform"
  subnet_ids = [
    aws_subnet.dev-private-a.id,
    aws_subnet.dev-private-c.id,
  ]
  tags = local.default_tags
}
