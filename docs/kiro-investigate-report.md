# Investigação: trocar a senha em docker/.env não afetava PostgreSQL e Moodle

(O caminho de saída do brief veio como o texto da própria pergunta; este relatório foi salvo neste arquivo.)

## Resposta resumida

Causa raiz: nos dois serviços (`db` e `moodle`), `env_file` apontava para `.env.example`, não para `.env`. O Compose resolve `env_file` relativo ao diretório do compose file, ou seja `docker/.env.example`. O arquivo `docker/.env` só era lido na interpolação `${VAR}`, e isso só alcançava o serviço `moodle`. O `db` ficava com os valores do template (`changeme_strong_password`), então a senha editada em `docker/.env` nunca chegava ao PostgreSQL.

Onde o `env_file` deve apontar: `.env` (ou seja `docker/.env`) nos dois serviços. O estado atual do repositório já está assim, corrigido no commit `362c0e8`.

## Evidências

- Histórico: `git log -p -S"env_file" -- docker/docker-compose.yml` mostra que o commit inicial `2f82ced` criou os dois blocos `env_file` com `- .env.example`. O commit `362c0e8` ("fix(docker): usar docker/.env no env_file e ajustar o docker-lint") trocou para `- .env`.
- `docker/docker-compose.yml` (hoje): `db.env_file: [.env]` e `moodle.env_file: [.env]`. O bloco `moodle.environment` lista `MOODLE_DATABASE_PASSWORD=${MOODLE_DATABASE_PASSWORD}` etc. O healthcheck do `db` usa `${POSTGRES_USER}` e `${POSTGRES_DB}`.
- Por que a falha era parcial: ao rodar `docker compose -f docker/docker-compose.yml`, o diretório de projeto é `docker/`. O Compose carrega `docker/.env` automaticamente só para interpolar `${...}`. Para o `moodle`, `environment` tem precedência sobre `env_file`, então ele recebia a senha nova de `.env`. O `db` não tem bloco `environment`, então recebia `POSTGRES_PASSWORD` do `.env.example`. Resultado possível: Moodle com senha nova, Postgres com a antiga, e falha de autenticação. Também explica por que mudar o `.env` "parecia não ter efeito".
- `docker/.env.example`: define `POSTGRES_PASSWORD` e `MOODLE_DATABASE_PASSWORD` com o mesmo valor placeholder. Os comentários dizem que devem coincidir. Não há erro no template. O `docker/.env` local tem as mesmas chaves (valores não lidos neste relatório).
- `.gitignore`: contém `.env`, `.env.*` e `!.env.example`. Isso é correto: `docker/.env` não é versionado e o template continua rastreado. O `.gitignore` não causa o problema, mas explica por que o `.env` não aparece no clone e precisa ser criado com `cp docker/.env.example docker/.env`.
- `.kiro/specs/docker-env-fix/tasks.md`: o plano da correção (trocar o `env_file`, copiar o `.env` no workflow `docker-lint`) está com todas as tarefas marcadas como concluídas.

## Ressalva que ainda pode fazer a troca de senha "não pegar"

O volume nomeado `db_data` guarda o cluster PostgreSQL. A imagem `postgres` só aplica `POSTGRES_PASSWORD` na primeira inicialização, com o diretório de dados vazio. Se o volume já existe, mudar a senha no `.env` não altera a senha do banco. Do mesmo modo, `moodle_data` guarda o `config.php` gerado na instalação, com a senha do banco da época. Não verifiquei o estado dos volumes (investigação somente leitura).

## Conclusões e recomendações

1. Causa raiz confirmada e já corrigida em `362c0e8`: `env_file: .env` em `db` e `moodle`. Nenhuma mudança adicional é necessária no compose.
2. Para aplicar uma senha nova em um ambiente que já foi iniciado, escolha uma destas opções:
   - Recriar do zero, perdendo os dados: `docker compose -f docker/docker-compose.yml down -v` e depois `up -d`.
   - Manter os dados: alterar a senha no banco com `ALTER USER moodle PASSWORD '...'` e atualizar o `config.php` do Moodle em `moodle_data`.
3. Para conferir o que o Compose usa, rode `docker compose -f docker/docker-compose.yml config` e veja as variáveis de `db` e `moodle`. As duas senhas devem ser iguais.
4. Opcional: documentar a ressalva do volume no README, na seção "Ambiente Docker Local".
