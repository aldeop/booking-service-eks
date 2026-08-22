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

# Superseded 2026-08-22: this used to be `random_password` + a plain
# `password` argument on the DB instance below, which meant the real
# password sat in local .tfstate (gitignored, but still a known
# limitation). Replaced with RDS's own `manage_master_user_password`
# integration instead -- AWS generates the password, stores ONLY
# `{"username": ..., "password": ...}` in a Secrets Manager secret it
# creates and rotates automatically (every 7 days by default), and the
# value never touches Terraform state at all. Verified against the RDS
# User Guide's Secrets Manager integration docs before building this.
resource "aws_db_instance" "booking_service" {
  identifier     = "booking-service-db"
  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

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

# --- IRSA: lets the booking-service pods assume an IAM role and read the
# DB secret above, instead of the app ever seeing a plain-env-var password.
#
# eksctl already registered an OIDC identity provider for this cluster
# (cluster-config.yaml has `iam.withOIDC: true`), so this is a lookup of an
# EXISTING provider, not a new resource -- AWS only allows one OIDC
# provider per issuer URL per account, so creating a second one here would
# conflict with what eksctl already made.
data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Trust policy: only a pod running as the `booking-service` ServiceAccount
# in the `booking-service` namespace can assume this role (the `sub`
# condition), and only via AWS STS's web-identity flow (the `aud`
# condition) -- this is the exact mechanism `eksctl create iamserviceaccount`
# automated for us back in Lesson 6; here we're building it by hand instead.
data "aws_iam_policy_document" "booking_service_irsa_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:booking-service:booking-service"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "booking_service_irsa" {
  name               = "booking-service-irsa"
  assume_role_policy = data.aws_iam_policy_document.booking_service_irsa_trust.json
}

# Scoped to exactly the one secret this app needs -- not
# SecretsManagerReadWrite or any other broad managed policy.
data "aws_iam_policy_document" "booking_service_read_db_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.booking_service.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "booking_service_read_db_secret" {
  name   = "read-db-secret"
  role   = aws_iam_role.booking_service_irsa.id
  policy = data.aws_iam_policy_document.booking_service_read_db_secret.json
}
