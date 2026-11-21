# Documento de Design: docker-env-fix

## Overview

A correção é de configuração e atinge dois arquivos: `docker/docker-compose.yml` e `.github/workflows/docker-lint.yml`. Não há código novo de aplicação. A linguagem dominante do workspace é Python (testes pytest + Hypothesis), usada nas verificações descritas aqui.

## Architecture

### Causa raiz

O Compose usa dois mecanismos de variáveis com fontes diferentes:

| Mecanismo | Fonte antes da correção | Efeito |
|---|---|---|
| `env_file:` (db e moodle) | `.env.example` | Injeta no contêiner os valores de exemplo, como `POSTGRES_PASSWORD=changeme_strong_password` |
| Interpolação `${...}` | `docker/.env` (lido automaticamente pelo Compose) | Define `MOODLE_DATABASE_PASSWORD` etc. no bloco `environment` do moodle |

Com a senha alterada no `.env`, o `db` inicializa com a senha de exemplo e o `moodle` tenta conectar com a senha nova.

### Solução

Os dois `env_file` passam a apontar para `.env`. O caminho é relativo ao diretório do Compose_File, então `.env` resolve para `docker/.env`, o mesmo arquivo usado na interpolação. Assim há uma única fonte de verdade.

Efeito colateral: `docker compose config` falha se `docker/.env` não existir. Por isso o workflow de CI copia o exemplo antes de validar.

## Components and Interfaces

### 1. `docker/docker-compose.yml`

Serviço `db`:

```yaml
    # Carrega as variáveis de ambiente a partir do docker/.env (copiado de .env.example)
    # TODO: Em produção, use senhas fortes no .env e nunca versione esse arquivo
    env_file:
      - .env
```

Serviço `moodle`:

```yaml
    # Carrega as variáveis de ambiente a partir do docker/.env (mesma fonte do db)
    env_file:
      - .env
```

O cabeçalho do arquivo já instrui `cp docker/.env.example docker/.env` e não muda. Os demais comentários `# TODO:` ficam intactos. O comentário `# TODO: Em produção, use o arquivo .env (sem valores de exemplo)` perde o sentido, porque `.env` agora é sempre usado. Ele é reescrito mantendo o prefixo `# TODO:`.

O bloco `environment` do moodle não muda. Os valores de credenciais continuam como `${VAR}`.

### 2. `.github/workflows/docker-lint.yml`

Novo step inserido entre o step do hadolint e o `Validar docker-compose.yml`:

```yaml
      # Cria o docker/.env a partir do exemplo, pois o .env real não é versionado
      # e o `docker compose config` exige o arquivo referenciado em env_file
      - name: Criar docker/.env a partir do exemplo
        run: cp docker/.env.example docker/.env
```

Os steps existentes, seus nomes e comentários não são alterados.

### 3. Verificações sem alteração de arquivo

- `.gitignore`: a regra `.env` na linha 72 (com `.env.*` e `!.env.example`) já ignora `docker/.env`. Conferir com `git check-ignore -v docker/.env`.
- `git ls-files docker` não lista `docker/.env`.
- `tests/test_compose_no_hardcoded_creds.py` lê apenas a seção `environment`, que não muda. Continua válido.
- `tests/test_todo_comments.py` exige `# TODO:` no compose. Os TODOs permanecem.
- `tests/test_workflow_step_comments.py` exige `name:` não vazio em todo step com `run:`. O novo step cumpre isso.

### 4. `README.md`

A seção "Ambiente Docker Local" já manda executar `cp .env.example .env` e ajustar as senhas, e informa que o `.env` real é ignorado pelo Git. Esse texto continua preciso. Nenhuma alteração é prevista. A tarefa de conferência só edita o README se encontrar uma afirmação que contradiga o novo comportamento.

## Data Models

O único modelo de dados é o arquivo `docker/.env`, com pares `CHAVE=valor` no formato de `docker/.env.example`: `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `MOODLE_DATABASE_HOST`, `MOODLE_DATABASE_PORT_NUMBER`, `MOODLE_DATABASE_NAME`, `MOODLE_DATABASE_USER`, `MOODLE_DATABASE_PASSWORD`, `MOODLE_USERNAME`, `MOODLE_PASSWORD` e `MOODLE_SITE_NAME`. Nenhuma chave é adicionada ou removida.

## Error Handling

- `docker/.env` ausente: `docker compose` falha com erro de arquivo não encontrado. O cabeçalho do compose e o README já instruem a cópia. No CI o novo step evita a falha.
- Senhas divergentes entre `POSTGRES_PASSWORD` e `MOODLE_DATABASE_PASSWORD` no `.env`: continua sendo erro do usuário. O `.env.example` já avisa que os valores devem coincidir.
- Volume `db_data` já inicializado com outra senha: o PostgreSQL ignora `POSTGRES_PASSWORD` em volume existente. Nesse caso o aluno deve rodar `docker compose down -v`. Isso fica fora do escopo da correção.

## Correctness Properties

*Uma propriedade é uma característica que deve valer em todas as execuções válidas do sistema. As propriedades ligam as especificações legíveis às garantias verificáveis por máquina.*

A correção altera configuração declarativa. Por isso a maior parte dos critérios é verificada por testes de exemplo e por verificações de arquivo. Os dois critérios abaixo variam sobre coleções (serviços, steps) e já têm cobertura por testes Hypothesis existentes.

### Property 1: Credenciais do compose usam interpolação

Para qualquer variável de `environment` de qualquer serviço do Compose_File cujo nome contenha `PASSWORD`, `SECRET`, `KEY` ou `TOKEN`, o valor declarado é vazio ou um único placeholder `${VAR}`.

**Validates: Requirements 4.1**

### Property 2: Todo step com `run:` tem nome

Para qualquer step com `run:` de qualquer workflow em `.github/workflows/`, o campo `name` existe e não é vazio. Isso inclui o novo step de cópia do `.env`.

**Validates: Requirements 3.3, 3.5**

Ambas as propriedades já estão implementadas em `tests/test_compose_no_hardcoded_creds.py` e `tests/test_workflow_step_comments.py`. Não é necessário criar novos testes de propriedade.

## Testing Strategy

- Testes existentes (pytest + Hypothesis, mínimo de 100 iterações nas propriedades) cobrem as Properties 1 e 2 e a presença de `# TODO:`.
- Verificação manual de integração, a ser executada pelo aluno ou mantenedor fora do orquestrador:
  - `cd tests && pytest -v`
  - copiar `docker/.env.example` para `docker/.env` e rodar `docker compose -f docker/docker-compose.yml config`
- Nenhum teste novo é obrigatório. Os critérios 1.1 a 1.3 e 3.1 a 3.2 são conferidos por inspeção do YAML e pelo `docker compose config`.

## Commits sugeridos

- `fix(docker): usar docker/.env no env_file de db e moodle`
- `ci(docker-lint): copiar .env.example para .env antes de validar o compose`
