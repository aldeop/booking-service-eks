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

output "db_master_password" {
  value     = random_password.db_master.result
  sensitive = true
}
