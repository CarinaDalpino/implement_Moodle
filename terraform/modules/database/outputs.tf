output "db_address" {
  description = "Hostname do RDS (sem porta)."
  value       = aws_db_instance.main.address
}

output "db_endpoint" {
  description = "Endpoint do RDS no formato host:porta."
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "Porta do RDS."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Nome do banco."
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Usuario do banco."
  value       = aws_db_instance.main.username
}

output "db_password" {
  description = "Senha do banco (sensivel), consumida pelo modulo compute."
  value       = aws_db_instance.main.password
  sensitive   = true
}
