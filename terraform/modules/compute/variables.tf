variable "project_name" {
  description = "Prefixo usado no nome dos recursos."
  type        = string
}

variable "subnet_id" {
  description = "Subnet publica da EC2."
  type        = string
}

variable "security_group_id" {
  description = "Security Group da EC2 (sg-app)."
  type        = string
}

variable "instance_type" {
  description = "Tipo da instancia EC2."
  type        = string
}

variable "instance_profile_name" {
  description = "Nome do instance profile pre-existente do Learner Lab."
  type        = string
}

variable "key_name" {
  description = "Key pair para SSH."
  type        = string
}

variable "repo_url" {
  description = "Repositorio com o docker/Dockerfile do Moodle."
  type        = string
}

variable "repo_branch" {
  description = "Branch a clonar."
  type        = string
}

variable "db_host" {
  description = "Hostname do RDS."
  type        = string
}

variable "db_port" {
  description = "Porta do RDS."
  type        = number
}

variable "db_name" {
  description = "Nome do banco."
  type        = string
}

variable "db_username" {
  description = "Usuario do banco."
  type        = string
}

variable "db_password" {
  description = "Senha do banco."
  type        = string
  sensitive   = true
}