module "networking" {
  source = "./modules/networking"

  project_name     = var.project_name
  vpc_cidr         = var.vpc_cidr
  ssh_allowed_cidr = var.ssh_allowed_cidr
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  db_security_group  = module.networking.sg_db_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  subnet_id             = module.networking.public_subnet_id
  security_group_id     = module.networking.sg_app_id
  instance_type         = var.instance_type
  instance_profile_name = var.instance_profile_name
  key_name              = var.key_name
  repo_url              = var.repo_url
  repo_branch           = var.repo_branch

  db_host     = module.database.db_address
  db_port     = module.database.db_port
  db_name     = module.database.db_name
  db_username = module.database.db_username
  db_password = module.database.db_password
}