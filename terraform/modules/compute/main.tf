# Instance profile pre-existente do Learner Lab. Nao criamos nenhum recurso IAM.
data "aws_iam_instance_profile" "lab" {
  name = var.instance_profile_name
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "moodle" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab.name
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh", {
    repo_url    = var.repo_url
    repo_branch = var.repo_branch
    db_host     = var.db_host
    db_port     = var.db_port
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-ec2" }
}