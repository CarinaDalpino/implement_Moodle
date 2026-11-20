# TODO: Parametrizar a quantidade de AZs para permitir mais de duas subnets por tipo.
variable "project_name" {
  description = "Prefixo usado no nome dos recursos."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorizado a acessar a EC2 por SSH."
  type        = string
}