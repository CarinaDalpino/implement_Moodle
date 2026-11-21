# Requirements Document

## Introduction

No ambiente Docker local, os serviços `db` e `moodle` de `docker/docker-compose.yml` carregam variáveis de `env_file: .env.example`. O arquivo `docker/.env` real só participa da interpolação `${...}`. Quando o aluno altera a senha no `.env`, o serviço `db` continua com `POSTGRES_PASSWORD=changeme_strong_password`, enquanto o serviço `moodle` recebe a senha nova pela interpolação. As duas senhas divergem e a conexão com o banco falha.

O enunciado da prova pede copiar `.env.example` para `.env` e ajustar as variáveis sem versionar senhas. Esta correção faz os dois serviços lerem `docker/.env` e ajusta o workflow de CI para que a validação do compose continue funcionando em um runner sem `.env`.

## Glossary

- **Compose_File**: arquivo `docker/docker-compose.yml`.
- **Env_File_Real**: arquivo `docker/.env`, criado pelo aluno a partir do exemplo e não versionado.
- **Env_Example**: arquivo `docker/.env.example`, versionado, com valores de exemplo.
- **Servico_Db**: serviço `db` (PostgreSQL 15) do Compose_File.
- **Servico_Moodle**: serviço `moodle` do Compose_File.
- **Workflow_Docker_Lint**: arquivo `.github/workflows/docker-lint.yml`.
- **Step_Validar_Compose**: step `Validar docker-compose.yml` do Workflow_Docker_Lint, que executa `docker compose config`.
- **Suite_Testes**: testes pytest em `tests/`.
- **Gitignore**: arquivo `.gitignore` da raiz do repositório.

## Requirements

### Requirement 1: Fonte única de variáveis no db e no moodle

**User Story:** Como aluno, eu quero que o `db` e o `moodle` leiam as variáveis do mesmo `docker/.env`, para que a troca de senha no `.env` valha para os dois serviços e a conexão funcione.

#### Acceptance Criteria

1. THE Compose_File SHALL declarar `.env` como único item de `env_file` do Servico_Db.
2. THE Compose_File SHALL declarar `.env` como único item de `env_file` do Servico_Moodle.
3. THE Compose_File SHALL conter zero referências a `.env.example` na seção `env_file` de qualquer serviço.
4. WHEN o aluno altera `POSTGRES_PASSWORD` e `MOODLE_DATABASE_PASSWORD` no Env_File_Real, THE Compose_File SHALL entregar os valores alterados ao Servico_Db e ao Servico_Moodle.

### Requirement 2: Comentários do compose atualizados

**User Story:** Como aluno, eu quero comentários corretos no compose, para que as instruções reflitam o uso do `.env`.

#### Acceptance Criteria

1. THE Compose_File SHALL descrever nos comentários vizinhos a cada `env_file` que as variáveis vêm do Env_File_Real.
2. THE Compose_File SHALL manter todos os comentários `# TODO:` existentes, alterando apenas o texto que menciona `.env.example` como fonte de variáveis.
3. THE Compose_File SHALL conter ao menos um comentário iniciado por `# TODO:`.

### Requirement 3: Workflow de lint sem docker/.env

**User Story:** Como mantenedor, eu quero que o workflow de lint continue passando sem `docker/.env`, para que o CI não falhe por falta de um arquivo que não é versionado.

#### Acceptance Criteria

1. THE Workflow_Docker_Lint SHALL conter um step que executa `cp docker/.env.example docker/.env`.
2. THE Workflow_Docker_Lint SHALL posicionar o step de cópia antes do Step_Validar_Compose.
3. THE Workflow_Docker_Lint SHALL atribuir um campo `name:` não vazio ao step de cópia.
4. THE Workflow_Docker_Lint SHALL preceder o step de cópia com um comentário que descreve sua finalidade.
5. THE Workflow_Docker_Lint SHALL preservar os nomes e os comentários dos steps existentes.

### Requirement 4: Segurança e testes preservados

**User Story:** Como mantenedor, eu quero que as garantias de segurança e de testes continuem válidas, para que a correção não reintroduza senhas versionadas.

#### Acceptance Criteria

1. THE Compose_File SHALL declarar as variáveis cujo nome contém `PASSWORD`, `SECRET`, `KEY` ou `TOKEN` usando apenas interpolação `${VAR}`.
2. THE Gitignore SHALL ignorar `docker/.env` e manter `docker/.env.example` versionável.
3. THE repositório Git SHALL conter zero ocorrências de `docker/.env` na lista de arquivos versionados.
4. THE Suite_Testes SHALL passar após as alterações, incluindo `tests/test_todo_comments.py`, `tests/test_workflow_step_comments.py` e `tests/test_compose_no_hardcoded_creds.py`.

### Requirement 5: README consistente

**User Story:** Como aluno, eu quero um README consistente com o comportamento do compose, para que as instruções de uso não me induzam a erro.

#### Acceptance Criteria

1. WHEN o texto da seção "Ambiente Docker Local" do `README.md` contradiz o uso de `docker/.env` pelos serviços, THE README SHALL ser atualizado para refletir esse uso.
2. IF o texto da seção "Ambiente Docker Local" já descreve a cópia de `.env.example` para `.env` e o ajuste das senhas, THEN THE README SHALL permanecer sem alterações.
