# Security Group for RDS
resource "aws_security_group" "dev" {
  vpc_id = aws_vpc.dev.id
  name   = "${local.sig}-sg-rds"

  ingress{
    description      = "from external server"
    from_port        = 3306
    to_port          = 3306
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
resource "aws_db_subnet_group" "dev" {
  name = "${local.sig}-db-subnet-group"
  subnet_ids = [
    aws_subnet.dev-private-a.id,
    aws_subnet.dev-private-c.id,
  ]
  tags = local.default_tags
}

# RDS Instance
resource "aws_db_instance" "dev" {
    # general
    identifier                            = local.sig
    instance_class                        = "db.t3.micro"
    engine                                = "mysql"
    engine_version                        = "8.0.32"
    username                              = var.db_username
    password                              = var.db_password
    db_name                               = "hoge_core" # DBName must begin with a letter and contain only alphanumeric characters.
    port                                  = 3306
    storage_type                          = "gp2"
    allocated_storage                     = 5

    # availability
    multi_az                              = false
    availability_zone                     = "ap-northeast-1c"
    backup_retention_period               = 5
    backup_window                         = "07:00-09:00"
    db_subnet_group_name                  = aws_db_subnet_group.dev.name
    skip_final_snapshot                   = true
    copy_tags_to_snapshot                 = true

    # maintenance
    auto_minor_version_upgrade            = true # Set to false for prod environment
    maintenance_window                    = "thu:14:00-thu:14:30"
    delete_automated_backups              = true
    deletion_protection                   = false # If true, protection enabled (Cannot be deleted)

    # monitoring
    monitoring_interval                   = 60
    monitoring_role_arn                   = "arn:aws:iam::XXXXXXXXXXX:role/rds-monitoring-role"

    # security
    ca_cert_identifier                    = "rds-ca-2019"
    parameter_group_name                  = aws_db_parameter_group.dev.name
    vpc_security_group_ids                = [aws_security_group.dev.id]

    tags = local.default_tags
}

# Parameters Group for RDS
resource "aws_db_parameter_group" "dev" {
  name   = "${local.sig}-rds-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "max_prepared_stmt_count"
    value = "16382"
  }

  parameter {
    name  = "general_log"
    value = "1" # enable only in development environment, specify 0 for production environment.
  }

  tags = local.default_tags
}

# IAM for Access From External Servers
resource "aws_iam_role" "dev" {
  name = "${local.sig}-external-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  tags = local.default_tags
}

resource "aws_iam_policy" "dev" {
  name        = "${local.sig}-external-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds:${var.aws_region}:${var.aws_account_id}:db:tag/project/hoge"
        ]
      }
    ]
  })
  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "dev" {
  policy_arn = aws_iam_policy.dev.arn
  role       = aws_iam_role.dev.name
}
