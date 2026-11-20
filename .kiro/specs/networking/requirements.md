# Requirements Document

## Introduction

Este documento especifica o módulo Terraform `networking` (`terraform/modules/networking/`) do projeto de implantação do Moodle na AWS. O módulo cria a base de rede: uma VPC, duas subnets públicas e duas subnets privadas em Zonas de Disponibilidade distintas, um Internet Gateway, uma Route Table pública e dois Security Groups (`sg-app` para a EC2 e `sg-db` para o RDS PostgreSQL).

O módulo opera no AWS Academy Learner Lab, que impõe restrições: região única `us-east-1`, proibição de criar usuários, grupos ou roles IAM e indisponibilidade de Route 53, ACM e CloudFront. Os módulos `compute` e `database` consomem os outputs do módulo.

## Glossary

- **Networking_Module**: Módulo Terraform localizado em `terraform/modules/networking/`.
- **VPC**: Virtual Private Cloud criada pelo Networking_Module.
- **Subnet_Publica**: Subnet com rota para o Internet_Gateway e atribuição automática de IP público.
- **Subnet_Privada**: Subnet sem rota para a internet, usada pelo DB Subnet Group do RDS.
- **AZ**: Zona de Disponibilidade da AWS, obtida pelo data source `aws_availability_zones`.
- **Internet_Gateway**: Recurso `aws_internet_gateway` que conecta a VPC à internet.
- **Route_Table_Publica**: Tabela de rotas com a rota `0.0.0.0/0` para o Internet_Gateway.
- **SG_App**: Security Group `sg-app` associado à instância EC2 do Moodle.
- **SG_Db**: Security Group `sg-db` associado à instância RDS PostgreSQL.
- **SSH_Allowed_CIDR**: Variável `ssh_allowed_cidr` com o CIDR autorizado a acessar a EC2 por SSH.
- **Learner_Lab**: Ambiente AWS Academy Learner Lab onde o projeto é implantado.
- **Modulo_Compute**: Módulo Terraform `terraform/modules/compute/`, consumidor dos outputs de subnet pública e SG_App.
- **Modulo_Database**: Módulo Terraform `terraform/modules/database/`, consumidor dos outputs de subnets privadas e SG_Db.

## Requirements

### Requisito 1

**User Story:** Como aluno, quero uma VPC com bloco CIDR documentado, para que todos os recursos do Moodle fiquem em uma rede isolada e previsível.

#### Acceptance Criteria

1. THE Networking_Module SHALL criar uma VPC com o bloco CIDR recebido pela variável `vpc_cidr`, cujo valor padrão na raiz é `10.0.0.0/16`.
2. THE Networking_Module SHALL habilitar `enable_dns_support` e `enable_dns_hostnames` na VPC.
3. THE Networking_Module SHALL nomear a VPC com a etiqueta `Name` no formato `<project_name>-vpc`.
4. THE Networking_Module SHALL documentar o bloco CIDR da VPC e das subnets em `docs/architecture-design.md`.

### Requisito 2

**User Story:** Como aluno, quero subnets públicas em AZs diferentes, para que a EC2 do Moodle receba tráfego da internet e a topologia suporte alta disponibilidade.

#### Acceptance Criteria

1. THE Networking_Module SHALL criar duas Subnet_Publica: `public_a` com CIDR `10.0.1.0/24` e `public_b` com CIDR `10.0.4.0/24`, derivados de `cidrsubnet(var.vpc_cidr, 8, n)`.
2. THE Networking_Module SHALL posicionar `public_a` na primeira AZ e `public_b` na segunda AZ retornadas por `aws_availability_zones` com estado `available`.
3. THE Networking_Module SHALL habilitar `map_public_ip_on_launch` nas duas Subnet_Publica.
4. THE Networking_Module SHALL nomear cada Subnet_Publica com a etiqueta `Name` no formato `<project_name>-public-a` ou `<project_name>-public-b`.

### Requisito 3

**User Story:** Como aluno, quero subnets privadas em AZs diferentes, para que o RDS possa criar um DB Subnet Group sem exposição à internet.

#### Acceptance Criteria

1. THE Networking_Module SHALL criar duas Subnet_Privada: `private_a` com CIDR `10.0.2.0/24` e `private_b` com CIDR `10.0.3.0/24`, derivados de `cidrsubnet(var.vpc_cidr, 8, n)`.
2. THE Networking_Module SHALL posicionar `private_a` na primeira AZ e `private_b` na segunda AZ retornadas por `aws_availability_zones`.
3. THE Networking_Module SHALL manter as duas Subnet_Privada sem rota para o Internet_Gateway, associadas apenas à tabela de rotas principal da VPC, que contém somente a rota local.
4. THE Networking_Module SHALL nomear cada Subnet_Privada com a etiqueta `Name` no formato `<project_name>-private-a` ou `<project_name>-private-b`.

### Requisito 4

**User Story:** Como aluno, quero um Internet Gateway e uma Route Table pública, para que as subnets públicas tenham saída e entrada de tráfego da internet.

#### Acceptance Criteria

1. THE Networking_Module SHALL criar um Internet_Gateway anexado à VPC.
2. THE Networking_Module SHALL criar uma Route_Table_Publica com a rota `0.0.0.0/0` apontando para o Internet_Gateway.
3. THE Networking_Module SHALL associar a Route_Table_Publica às duas Subnet_Publica.
4. THE Networking_Module SHALL nomear o Internet_Gateway e a Route_Table_Publica com as etiquetas `Name` `<project_name>-igw` e `<project_name>-public-rt`.

### Requisito 5

**User Story:** Como aluno, quero um Security Group para a EC2, para que o Moodle receba HTTP da internet e SSH apenas do meu IP.

#### Acceptance Criteria

1. THE Networking_Module SHALL criar o SG_App com o nome `<project_name>-sg-app` na VPC.
2. THE Networking_Module SHALL permitir no SG_App entrada TCP na porta 80 a partir de `0.0.0.0/0`.
3. THE Networking_Module SHALL permitir no SG_App entrada TCP na porta 22 somente a partir do SSH_Allowed_CIDR.
4. THE Networking_Module SHALL permitir no SG_App saída para todos os protocolos e destinos `0.0.0.0/0`.
5. THE Networking_Module SHALL definir as regras do SG_App com os recursos `aws_vpc_security_group_ingress_rule` e `aws_vpc_security_group_egress_rule`.

### Requisito 6

**User Story:** Como aluno, quero um Security Group para o banco de dados, para que o RDS aceite conexões somente da EC2.

#### Acceptance Criteria

1. THE Networking_Module SHALL criar o SG_Db com o nome `<project_name>-sg-db` na VPC.
2. THE Networking_Module SHALL permitir no SG_Db entrada TCP na porta 5432 somente a partir do SG_App, referenciado por `referenced_security_group_id`.
3. THE Networking_Module SHALL definir o SG_Db sem nenhuma regra de entrada com origem em bloco CIDR, o que bloqueia toda origem externa.

### Requisito 7

**User Story:** Como aluno, quero que a rede respeite as restrições do Learner Lab, para que a implantação não seja bloqueada pelo ambiente.

#### Acceptance Criteria

1. THE Networking_Module SHALL operar somente na região `us-east-1`, definida pela variável raiz `aws_region`.
2. THE Networking_Module SHALL declarar apenas recursos de rede (`aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table`, `aws_route_table_association`, `aws_security_group` e regras de Security Group) e nenhum recurso IAM.
3. THE Networking_Module SHALL omitir recursos Route 53, ACM e CloudFront.

### Requisito 8

**User Story:** Como desenvolvedor dos módulos `compute` e `database`, quero outputs do módulo de rede, para que eu consuma IDs de subnets e Security Groups sem duplicar configuração.

#### Acceptance Criteria

1. THE Networking_Module SHALL expor os outputs `vpc_id`, `public_subnet_id`, `public_subnet_ids`, `private_subnet_ids`, `sg_app_id` e `sg_db_id`.
2. THE Networking_Module SHALL expor em `public_subnet_id` o ID da subnet `public_a`, consumido pelo Modulo_Compute.
3. THE Networking_Module SHALL expor em `private_subnet_ids` uma lista com os IDs de `private_a` e `private_b`, consumida pelo Modulo_Database.
4. THE Networking_Module SHALL expor em `sg_app_id` o ID do SG_App, consumido pelo Modulo_Compute, e em `sg_db_id` o ID do SG_Db, consumido pelo Modulo_Database.

### Requisito 9

**User Story:** Como aluno, quero impedir que o SSH fique aberto para a internet, para que a EC2 não seja exposta a acessos indevidos.

#### Acceptance Criteria

1. IF o valor de `ssh_allowed_cidr` na raiz for `0.0.0.0/0`, THEN THE Terraform SHALL rejeitar a configuração com a mensagem de erro `ssh_allowed_cidr nao pode ser 0.0.0.0/0. Informe o seu IP no formato x.x.x.x/32.`
2. THE Networking_Module SHALL receber `ssh_allowed_cidr` do módulo raiz sem valor padrão, o que obriga o aluno a informar o próprio IP.

### Requisito 10

**User Story:** Como aluno, quero validações automáticas do módulo, para que eu comprove a qualidade do código Terraform na avaliação.

#### Acceptance Criteria

1. WHEN o comando `terraform fmt -check -recursive` é executado em `terraform/`, THE Networking_Module SHALL passar sem diferenças de formatação.
2. WHEN o comando `terraform validate` é executado em `terraform/`, THE Networking_Module SHALL passar sem erros.
3. WHEN o comando `terraform plan` é executado com as credenciais do Learner Lab, THE Networking_Module SHALL produzir um plano sem erros.
4. THE Networking_Module SHALL registrar as evidências das validações (capturas de tela de `fmt`, `validate` e `plan`) na documentação do projeto.
