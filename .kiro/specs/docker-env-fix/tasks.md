# Implementation Plan: docker-env-fix

## Overview

Trocar o `env_file` dos serviços `db` e `moodle` de `.env.example` para `.env`, adaptar o workflow de lint para criar o `.env` no runner e conferir que testes, `.gitignore` e README continuam consistentes. Nenhuma tarefa está concluída.

## Tasks

- [x] 1. Corrigir `env_file` no docker-compose.yml
  - [x] 1.1 Trocar `.env.example` por `.env` nos serviços `db` e `moodle`
    - Em `docker/docker-compose.yml`, alterar os dois blocos `env_file` para `- .env`
    - Atualizar os comentários vizinhos para dizer que as variáveis vêm de `docker/.env`
    - Manter todos os comentários `# TODO:`; reescrever o TODO "Em produção, use o arquivo .env" mantendo o prefixo `# TODO:`
    - Commit sugerido: `fix(docker): usar docker/.env no env_file de db e moodle`
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3_

- [x] 2. Ajustar o workflow de lint
  - [x] 2.1 Adicionar step que cria `docker/.env` antes de validar o compose
    - Em `.github/workflows/docker-lint.yml`, inserir antes do step `Validar docker-compose.yml` um step com `name:` e comentário acima, executando `cp docker/.env.example docker/.env`
    - Preservar os nomes e comentários dos steps existentes
    - Commit sugerido: `ci(docker-lint): copiar .env.example para .env antes de validar o compose`
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Conferir consistência do repositório
  - [x] 3.1 Conferir testes, `.gitignore` e README
    - Ler `tests/test_compose_no_hardcoded_creds.py` e confirmar que só inspeciona `environment` e continua válido
    - Confirmar que `docker/.env` está ignorado (`git check-ignore -v docker/.env`) e ausente de `git ls-files docker`
    - Reler a seção "Ambiente Docker Local" do `README.md`; editar somente se houver trecho impreciso (commit `docs:` se editar)
    - _Requisitos: 4.1, 4.2, 4.3, 5.1, 5.2_

- [x] 4. Checkpoint final: validar testes e compose
  - Rodar `cd tests && pytest -v` e confirmar que todos os testes passam
  - Copiar `docker/.env.example` para `docker/.env` e rodar `docker compose -f docker/docker-compose.yml config`; confirmar saída sem erros e com as senhas do `.env` nos dois serviços
  - Remover o `docker/.env` de teste se não for usado, e confirmar que `git status` não o lista
  - Em caso de dúvida, perguntar ao usuário
  - _Requisitos: 1.4, 4.4_

## Notes

- Não há tarefas opcionais: a correção é pequena e os testes de propriedade já existem.
- O `docker/.env` nunca deve ser versionado.
- As tarefas 1.1 e 2.1 editam arquivos diferentes e podem seguir em paralelo.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1"] },
    { "id": 1, "tasks": ["3.1"] }
  ]
}
```
