variable "aws_region" {
  description = "AWS region the Pluralsight sandbox cluster runs in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile with sandbox credentials"
  type        = string
  default     = "ps-sandbox"
}

variable "cluster_name" {
  description = "Name of the EKS cluster whose VPC/subnets/node SG this DB attaches to"
  type        = string
  default     = "sandbox-lab"
}

variable "db_instance_class" {
  description = "RDS instance class -- must stay within the sandbox's t3/t4g micro-small-medium limit"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage in GB -- sandbox caps RDS at 50GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name -- must match app/config.py's database_name default"
  type        = string
  default     = "booking"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "bookingadmin"
}
