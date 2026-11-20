output "vpc_id" {
  description = "ID da VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Subnet publica onde roda a EC2."
  value       = aws_subnet.public_a.id
}

output "public_subnet_ids" {
  description = "IDs das subnets publicas."
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (2 AZs) para o DB Subnet Group."
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "sg_app_id" {
  description = "Security Group da EC2."
  value       = aws_security_group.app.id
}

output "sg_db_id" {
  description = "Security Group do RDS."
  value       = aws_security_group.db.id
}