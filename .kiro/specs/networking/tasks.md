# Implementation Plan: Módulo Terraform networking

## Overview

O módulo `networking` já está implementado em `terraform/modules/networking/`. Este plano registra as tarefas realizadas (marcadas com `[x]`) e as pendentes: executar `terraform plan` com credenciais do Learner Lab e coletar as evidências.

## Tasks

- [x] 1. Criar a estrutura do módulo e a VPC
  - [x] 1.1 Criar `variables.tf` com `project_name`, `vpc_cidr` e `ssh_allowed_cidr`
    - _Requisitos: 1.1, 5.3_
  - [x] 1.2 Criar a VPC em `main.tf` com DNS support e hostnames habilitados
    - Etiqueta `Name` no formato `<project_name>-vpc`
    - _Requisitos: 1.1, 1.2, 1.3, 7.1_

- [x] 2. Criar as subnets públicas e privadas
  - [x] 2.1 Declarar o data source `aws_availability_zones` e os locals `az_a` e `az_b`
    - _Requisitos: 2.2, 3.2_
  - [x] 2.2 Criar `public_a` e `public_b` com `cidrsubnet` e `map_public_ip_on_launch`
    - CIDRs `10.0.1.0/24` e `10.0.4.0/24`
    - _Requisitos: 2.1, 2.3, 2.4_
  - [x] 2.3 Criar `private_a` e `private_b` com `cidrsubnet`, sem IP público
    - CIDRs `10.0.2.0/24` e `10.0.3.0/24`
    - _Requisitos: 3.1, 3.3, 3.4_

- [x] 3. Configurar a saída para a internet
  - [x] 3.1 Criar o Internet Gateway e a Route Table pública com a rota `0.0.0.0/0`
    - _Requisitos: 4.1, 4.2, 4.4_
  - [x] 3.2 Associar a Route Table pública a `public_a` e `public_b`
    - _Requisitos: 4.3_

- [x] 4. Criar os Security Groups
  - [x] 4.1 Criar o `sg-app` com entrada TCP 80 e TCP 22 (restrita ao `ssh_allowed_cidr`) e saída irrestrita
    - Usar `aws_vpc_security_group_ingress_rule` e `aws_vpc_security_group_egress_rule`
    - _Requisitos: 5.1, 5.2, 5.3, 5.4, 5.5_
  - [x] 4.2 Criar o `sg-db` com entrada TCP 5432 somente a partir do `sg-app`
    - Usar `referenced_security_group_id`, sem regras baseadas em CIDR
    - _Requisitos: 6.1, 6.2, 6.3_

- [x] 5. Expor outputs e integrar ao módulo raiz
  - [x] 5.1 Criar `outputs.tf` com `vpc_id`, `public_subnet_id`, `public_subnet_ids`, `private_subnet_ids`, `sg_app_id` e `sg_db_id`
    - _Requisitos: 8.1, 8.2, 8.3, 8.4_
  - [x] 5.2 Chamar o módulo em `terraform/main.tf` e ligar os outputs a `compute` e `database`
    - _Requisitos: 8.2, 8.3, 8.4_
  - [x] 5.3 Adicionar a validação de `ssh_allowed_cidr` em `terraform/variables.tf`, recusando `0.0.0.0/0`
    - _Requisitos: 9.1, 9.2_

- [x] 6. Executar as validações estáticas
  - [x] 6.1 Executar `terraform fmt -check -recursive` e `terraform validate` sem erros
    - _Requisitos: 10.1, 10.2_

- [x] 7. Validar o plano e registrar evidências
  - [x] 7.1 Executar `terraform plan` com credenciais do Learner Lab e conferir que não há erros nem recursos IAM
    - _Requisitos: 7.2, 7.3, 10.3_
  - [x] 7.2 Capturar as telas de `fmt`, `validate` e `plan` e anexá-las à documentação
    - _Requisitos: 1.4, 10.4_

- [x] 8. Checkpoint final
  - Garantir que as validações passam e consultar o usuário se surgirem dúvidas.

## Notes

- As tarefas 7.1 e 7.2 foram executadas com credenciais do Learner Lab: `terraform plan` retornou `Plan: 19 to add, 0 to change, 0 to destroy`, sem recursos IAM. Evidências em `docs/img/terraform-validate.png`, `docs/img/terraform-plan.png` e `docs/img/terraform-plan-inicio.png`.
- Como o módulo é Infraestrutura como Código, não há tarefas de testes baseados em propriedades.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "2.1"] },
    { "id": 2, "tasks": ["2.2", "2.3"] },
    { "id": 3, "tasks": ["3.1"] },
    { "id": 4, "tasks": ["3.2", "4.1"] },
    { "id": 5, "tasks": ["4.2"] },
    { "id": 6, "tasks": ["5.1"] },
    { "id": 7, "tasks": ["5.2", "5.3"] },
    { "id": 8, "tasks": ["6.1"] },
    { "id": 9, "tasks": ["7.1"] },
    { "id": 10, "tasks": ["7.2"] }
  ]
}
```
