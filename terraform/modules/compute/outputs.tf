output "public_ip" {
  description = "IP publico da EC2."
  value       = aws_instance.moodle.public_ip
}

output "public_dns" {
  description = "DNS publico da EC2."
  value       = aws_instance.moodle.public_dns
}

output "instance_id" {
  description = "ID da instancia EC2."
  value       = aws_instance.moodle.id
}