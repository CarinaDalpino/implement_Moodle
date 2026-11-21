# Moodle Docker AWS Challenge

Solução do desafio **Moodle Docker AWS** (DevOps, ADS UniFAAT, 2026.2), feita a partir do template [AleTavares/implement_Moodle](https://github.com/AleTavares/implement_Moodle). O Moodle 4.1 roda localmente com Docker Compose (Moodle + PostgreSQL 15) e na AWS, numa EC2 com banco RDS PostgreSQL 15. Toda a infraestrutura AWS é criada com Terraform no AWS Academy Learner Lab.

→ [Desafio completo](CHALLENGE.md) · [Documento de arquitetura](docs/architecture-design.md) · [Spec do Kiro (networking)](.kiro/specs/networking/)


## Pré-requisitos

| Ferramenta | Versão mínima | Para quê |
|---|---|---|
| [Docker Engine](https://docs.docker.com/get-docker/) | 24.x | Ambiente local. Inclui o Docker Compose v2 (`docker compose`) |
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.5+ | Infraestrutura AWS (provider AWS `~> 5.0`) |
| [AWS CLI](https://aws.amazon.com/cli/) | 2.x | Credenciais do Learner Lab |
| [Git](https://git-scm.com/) | 2.x | Clonar o repositório |
| [Python](https://www.python.org/) | 3.8+ | Testes (`pytest`, `hypothesis`, `pyyaml`) |
| AWS Academy Learner Lab | — | Credenciais temporárias, região `us-east-1` |

O Learner Lab fornece credenciais que expiram em cerca de 4 horas e não permite criar IAM, Route 53, ACM nem CloudFront. Veja [`docs/aws-learn-lab-setup.md`](docs/aws-learn-lab-setup.md).


## Estrutura do Repositório

```
.
├── .github/workflows/
│   ├── docker-lint.yml              # hadolint no Dockerfile + validação do compose
│   ├── health-check.yml             # health check manual contra uma URL
│   ├── terraform-plan.yml           # terraform plan em cada PR, com comentário no PR
│   └── terraform-validate.yml       # terraform fmt -check + validate
├── .kiro/specs/networking/          # Spec do Kiro: requirements, design e tasks
├── docker/                          # Ambiente local: Dockerfile, docker-compose.yml, .env.example
├── docs/
│   ├── architecture-design.md       # Documento de arquitetura da solução (entrega)
│   ├── img/                         # Evidências (prints)
│   └── ...                          # Guias do template
├── scripts/health-check.sh          # Verifica se o Moodle está respondendo
├── terraform/
│   ├── versions.tf                  # Terraform >= 1.5, provider AWS ~> 5.0, região
│   ├── main.tf                      # Liga os módulos networking → database → compute
│   ├── variables.tf                 # Variáveis raiz (senha e IP do SSH são sensitive)
│   ├── outputs.tf                   # vpc_id, ec2_public_dns, moodle_url, rds_endpoint
│   ├── terraform.tfvars.example     # Modelo do terraform.tfvars (o real não vai para o Git)
│   └── modules/
│       ├── networking/              # VPC, 2 subnets públicas, 2 privadas, IGW, rotas, sg-app, sg-db
│       ├── compute/                 # EC2 t3.micro, LabInstanceProfile, user_data.sh
│       └── database/                # RDS PostgreSQL 15 db.t3.micro privado, subnet group
└── tests/                           # Testes do repositório (pytest + Hypothesis)
```


## Ambiente Docker Local

```bash
cd docker
cp .env.example .env          # ajuste as senhas; o .env real é ignorado pelo Git
docker compose up -d
docker compose ps             # db (healthy) e moodle (porta 8080)
```

Abra http://localhost:8080 e conclua o instalador web:

| Campo | Valor |
|---|---|
| Driver | PostgreSQL (native/pgsql) |
| Host | `db` |
| Base de dados / Usuário | `moodle` / `moodle` |
| Senha | `POSTGRES_PASSWORD` do seu `.env` |
| Porta | `5432` |

O Dockerfile instala a extensão PHP `pgsql`. Sem ela, o instalador só oferece MySQL.

```bash
docker compose logs -f moodle  # logs do Moodle
docker compose down            # para os contêineres (mantém os volumes)
docker compose down -v         # para e apaga os volumes (apaga os dados)
```

Os dados ficam nos volumes nomeados `db_data`, `moodle_data` e `moodle_www` e sobrevivem a `docker compose restart`.


## Infraestrutura AWS com Terraform

### 1. Credenciais do Learner Lab

No Learner Lab, clique em **Start Lab**, depois em **AWS Details → AWS CLI: Show**, e cole o bloco em `~/.aws/credentials`. Confira:

```bash
aws sts get-caller-identity
```

### 2. Variáveis

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
curl -s https://checkip.amazonaws.com      # seu IP público
```

Edite o `terraform.tfvars`:

```hcl
ssh_allowed_cidr = "SEU_IP/32"            # 0.0.0.0/0 é recusado pela validação
db_password      = "SenhaForteComDozeCaracteres"
```

O `terraform.tfvars` está no `.gitignore`. As duas variáveis são `sensitive` e não aparecem na saída do `plan`.

### 3. Init, validação e plano

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan        # Plan: 19 to add, 0 to change, 0 to destroy.
```

### 4. Apply

```bash
terraform apply
```

O RDS leva cerca de 7 minutos para ficar pronto. Depois disso, o `user_data.sh` da EC2 instala o Docker e o Compose v2, clona este repositório, constrói a imagem do Moodle e executa `docker compose up -d`. Isso leva mais uns 10 a 15 minutos na `t3.micro`.

### 5. URL pública do Moodle

```bash
terraform output moodle_url      # http://ec2-x-x-x-x.compute-1.amazonaws.com
terraform output rds_endpoint    # host:5432 do RDS
```

Abra a `moodle_url` e conclua o instalador com o driver **PostgreSQL**, o host do `rds_endpoint` (sem `:5432`), a base `moodle`, o usuário `moodle` e a senha do `terraform.tfvars`. Para confirmar que está tudo no ar:

```bash
../scripts/health-check.sh "$(terraform output -raw moodle_url)"
```

Para acompanhar o boot da EC2, o log fica em `/var/log/user-data.log`. Acesse com `ssh -i labsuser.pem ec2-user@<ec2_public_ip>`, usando a chave `vockey` do Learner Lab.

### 6. Destroy

```bash
terraform destroy
```

Rode sempre ao terminar, para não consumir o crédito do Lab. O RDS está com `skip_final_snapshot = true`, então nada fica para trás.


## CI/CD

| Workflow | Gatilho | O que faz |
|---|---|---|
| [`terraform-plan.yml`](.github/workflows/terraform-plan.yml) | PR para `main` (em `terraform/**`) e `workflow_dispatch` | Autentica com as credenciais do Learner Lab (incluindo o session token), roda `init`, `validate` e `plan -no-color`, comenta o plano no PR e falha se o `plan` der erro |
| [`terraform-validate.yml`](.github/workflows/terraform-validate.yml) | push e PR para `main` | `terraform fmt -check -recursive` e `terraform validate` |
| [`docker-lint.yml`](.github/workflows/docker-lint.yml) | push e PR em `docker/**` e `workflow_dispatch` | `hadolint` no Dockerfile (DL3008 ignorada) e `docker compose config` |
| [`health-check.yml`](.github/workflows/health-check.yml) | `workflow_dispatch` com input `moodle_url` | Roda `scripts/health-check.sh` contra a URL informada |

Secrets necessários em **Settings → Secrets and variables → Actions**:

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | credenciais do Learner Lab (atualize a cada sessão) |
| `TF_VAR_DB_PASSWORD` | senha do RDS |
| `TF_VAR_SSH_ALLOWED_CIDR` | seu IP no formato `x.x.x.x/32` |

Com o GitHub CLI, os três secrets da AWS podem ser atualizados direto do `~/.aws/credentials`:

```bash
R=CarinaDalpino/implement_Moodle
gh secret set AWS_ACCESS_KEY_ID     --repo $R --body "$(aws configure get aws_access_key_id)"
gh secret set AWS_SECRET_ACCESS_KEY --repo $R --body "$(aws configure get aws_secret_access_key)"
gh secret set AWS_SESSION_TOKEN     --repo $R --body "$(aws configure get aws_session_token)"
```


## Testes

```bash
python3 -m venv ~/.venvs/moodle
~/.venvs/moodle/bin/pip install pytest hypothesis pyyaml
cd tests
~/.venvs/moodle/bin/pytest -v
```

Os testes inspecionam o repositório (extensões PHP do Dockerfile, credenciais no compose, `.gitignore`, estrutura dos módulos Terraform, comentários `# TODO:`, nomes dos steps dos workflows, seções do documento de arquitetura e o `health-check.sh`). Eles não precisam de AWS.


## Evidências

| Evidência | Arquivo |
|---|---|
| Moodle local e contêineres | [`docs/img/print-moodle.png`](docs/img/print-moodle.png), [`docs/img/docker.png`](docs/img/docker.png) |
| `terraform fmt` e `validate` | [`docs/img/terraform-validate.png`](docs/img/terraform-validate.png) |
| `terraform plan` | [`docs/img/terraform-plan.png`](docs/img/terraform-plan.png), [`docs/img/terraform-plan-inicio.png`](docs/img/terraform-plan-inicio.png) |
| `terraform output` após o apply | [`docs/img/terraform-output.png`](docs/img/terraform-output.png) |
| Moodle na EC2 | [`docs/img/moodle-aws.png`](docs/img/moodle-aws.png) |
| Workflows no GitHub Actions | [`docs/img/github-actions.png`](docs/img/github-actions.png), [`docs/img/github-actions-plan.png`](docs/img/github-actions-plan.png) |
| Comentário do plan no PR | [`docs/img/github-pr-comment.png`](docs/img/github-pr-comment.png) |
| Health Check contra a EC2 | [`docs/img/github-health-check.png`](docs/img/github-health-check.png) |


## Documentação

| Documento | Descrição |
|---|---|
| [`docs/architecture-design.md`](docs/architecture-design.md) | Arquitetura da solução: diagrama, componentes, segurança, escalabilidade e custo |
| [`docs/aws-learn-lab-setup.md`](docs/aws-learn-lab-setup.md) | Credenciais e limitações do Learner Lab |
| [`docs/terraform-guide.md`](docs/terraform-guide.md) | Referência dos comandos Terraform |
| [`docs/security-practices.md`](docs/security-practices.md) | Boas práticas de segurança |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | Problemas comuns e soluções |
| [`docs/evaluation-rubric.md`](docs/evaluation-rubric.md) | Rubrica de avaliação |