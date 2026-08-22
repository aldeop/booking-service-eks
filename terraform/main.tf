# Reads the EKS cluster's own VPC config rather than hardcoding subnet/SG IDs
# -- the Pluralsight sandbox hands you a brand new VPC every session (the
# cluster itself is rebuilt via ../aws-sandbox/bootstrap.sh each time), so
# anything hardcoded here would silently break on the very next session.
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

resource "aws_db_subnet_group" "booking_service" {
  name        = "booking-service-db-subnet-group"
  description = "Subnets for booking-service RDS instance"
  subnet_ids  = data.aws_eks_cluster.this.vpc_config[0].subnet_ids
}

resource "aws_security_group" "booking_service_db" {
  name        = "booking-service-db-sg"
  description = "Allow Postgres from EKS worker nodes only"
  vpc_id      = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  ingress {
    description     = "Postgres from EKS worker nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
  }

  # Deliberately no egress block: RDS doesn't need outbound access via its
  # own SG for normal operation, so deny-all-outbound is the correct
  # starting point here, not an oversight.
}

# Generated rather than typed by hand, so the credential never touches shell
# history or CLI args. It still lands in the local .tfstate file, though --
# which is exactly why *.tfstate is gitignored, and why this pattern doesn't
# scale to a real team. A production setup would have Terraform provision
# the DB but source/rotate the credential via AWS Secrets Manager, synced
# into the cluster with something like External Secrets Operator, so the
# raw value never sits in Terraform state at all. Fine for a single-user
# ephemeral lab; noted here as a real limitation, not a blind spot.
resource "random_password" "db_master" {
  length  = 24
  special = false
}

resource "aws_db_instance" "booking_service" {
  identifier     = "booking-service-db"
  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master.result

  db_subnet_group_name   = aws_db_subnet_group.booking_service.name
  vpc_security_group_ids = [aws_security_group.booking_service_db.id]

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0

  # The sandbox DB gets wiped every session anyway -- skip_final_snapshot
  # keeps `terraform destroy` from hanging on a snapshot request that would
  # outlive the lab session.
  skip_final_snapshot = true
  deletion_protection = false
}
