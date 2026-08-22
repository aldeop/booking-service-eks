output "db_endpoint" {
  description = "RDS instance endpoint hostname (no port)"
  value       = aws_db_instance.booking_service.address
}

output "db_port" {
  value = aws_db_instance.booking_service.port
}

output "db_master_username" {
  value = var.db_username
}

# No password output anymore -- RDS manages it, and the app fetches it at
# runtime via IRSA + this secret's ARN, not via Terraform state.
output "db_secret_arn" {
  description = "Secrets Manager secret ARN holding the RDS-managed master credentials"
  value       = aws_db_instance.booking_service.master_user_secret[0].secret_arn
}

output "irsa_role_arn" {
  description = "IAM role ARN for the booking-service ServiceAccount to assume via IRSA"
  value       = aws_iam_role.booking_service_irsa.arn
}
