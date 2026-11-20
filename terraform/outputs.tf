output "vpc_id" {
  description = "ID da VPC."
  value       = module.networking.vpc_id
}

output "ec2_public_ip" {
  description = "IP publico da EC2."
  value       = module.compute.public_ip
}

output "ec2_public_dns" {
  description = "DNS publico da EC2."
  value       = module.compute.public_dns
}

output "moodle_url" {
  description = "URL para acessar o Moodle (HTTP, porta 80)."
  value       = "http://${module.compute.public_dns}"
}

output "rds_endpoint" {
  description = "Endpoint do RDS (host:porta). Use este host no instalador web do Moodle."
  value       = module.database.db_endpoint
}