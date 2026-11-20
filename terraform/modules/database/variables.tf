# TODO: Parametrizar instance_class e allocated_storage para ambientes maiores.
variable "project_name" {
  description = "Prefixo usado no nome dos recursos."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas (minimo 2 AZs) para o DB Subnet Group."
  type        = list(string)
}

variable "db_security_group" {
  description = "ID do Security Group do RDS."
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados."
  type        = string
}

variable "db_username" {
  description = "Usuario administrador do banco."
  type        = string
}

variable "db_password" {
  description = "Senha do banco."
  type        = string
  sensitive   = true
}