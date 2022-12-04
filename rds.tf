resource "aws_security_group" "pod_access_db_sg" {
  name = "K8S pods access RDS Security Group"
  vpc_id = aws_vpc.eks-test_vpc.id
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
    ]
  }
  tags = {
    Name        = "RDS Security Group"
    Terraform   = "true"
  }
}



resource "aws_db_subnet_group" "rds-db-subnet" {
  name = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.eks-test-private-1a.id,
    aws_subnet.eks-test-private-1b.id
    ]

  tags = {
    Name        = "DB Subnet Group"
    Terraform   = "true"
  }
}


resource "aws_db_instance" "k8s-pod-db" {
  allocated_storage       = "20"
  storage_type            = "gp2"
  #storage_type            = "io1"   io1 size at least 100G
  #iops = "3000"
  engine                  = "postgres"
  engine_version          = "14.1"
  multi_az                = "false"  # for save the cost, for production should be true
  #monitoring_interval = "30" # interval of Enhanced Monitoring metrics are collected for the DB instance
  #monitoring_role_arn         = "${aws_iam_role.rds_monitoring_iam_role.arn}"
  instance_class          = "db.t3.medium"
  db_name                    = "kubernetesdb"
  # Set the secrets from AWS Secrets Manager
  username = "postgres"
  password = "${random_string.password.result}"
  identifier              = "kubernetesdb"
  skip_final_snapshot     = "true"
  publicly_accessible    = "false"
  #performance_insights_enabled = true
  #performance_insights_retention_period = 7
  backup_retention_period = "1"
  # DB Instance class db.t2.micro does not support encryption at rest
  #storage_encrypted       = "true"
  db_subnet_group_name    = aws_db_subnet_group.rds-db-subnet.name
  vpc_security_group_ids  = [aws_security_group.pod_access_db_sg.id]
   tags = {
    Name        = "RDS for K8S pod Database"
    Terraform   = "true"
  }
}



resource "random_string" "password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "rdspassword" {
  name = "rds-password"
  type        = "SecureString"
  value = "${random_string.password.result}"
}


resource "aws_ssm_parameter" "rds-endpoint" {
  name = "rds-endpoint"
  type = "String"
  value = "${aws_db_instance.k8s-pod-db.address}"
}

