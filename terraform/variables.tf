variable "aws_region" {
  description = "Regiao AWS. O Learner Lab opera somente em us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo usado no nome dos recursos."
  type        = string
  default     = "moodle"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorizado a acessar a EC2 por SSH (ex.: 203.0.113.10/32). Nao use 0.0.0.0/0."
  type        = string

  validation {
    condition     = var.ssh_allowed_cidr != "0.0.0.0/0"
    error_message = "ssh_allowed_cidr nao pode ser 0.0.0.0/0. Informe o seu IP no formato x.x.x.x/32."
  }
}

variable "key_name" {
  description = "Nome do key pair existente para SSH. No Learner Lab o padrao e vockey."
  type        = string
  default     = "vockey"
}

variable "instance_type" {
  description = "Tipo da instancia EC2."
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = "Instance profile pre-existente do Learner Lab (nao e criado pelo Terraform)."
  type        = string
  default     = "LabInstanceProfile"
}

variable "db_name" {
  description = "Nome do banco de dados do Moodle."
  type        = string
  default     = "moodle"
}

variable "db_username" {
  description = "Usuario administrador do RDS."
  type        = string
  default     = "moodle"
}

variable "db_password" {
  description = "Senha do RDS. Informe por terraform.tfvars (ignorado pelo Git) ou TF_VAR_db_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "A senha do banco deve ter pelo menos 12 caracteres."
  }
}

variable "repo_url" {
  description = "Repositorio publico com o docker/Dockerfile usado para construir a imagem do Moodle na EC2."
  type        = string
  default     = "https://github.com/CarinaDalpino/implement_Moodle.git"
}

variable "repo_branch" {
  description = "Branch do repositorio a ser clonada na EC2."
  type        = string
  default     = "main"
}