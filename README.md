# Zubio

SaaS de agendamentos online, multi-tenant e whitelabel, para salões, barbearias e profissionais autônomos (psicólogos etc.). Subdomínio por tenant (`<estabelecimento>.zubio.com.br`). PWA servido pelo próprio Rails.

## Stack

- **Backend**: Ruby 4.0.1, Rails 8.1, PostgreSQL
- **Frontend**: Phlex (componentes Ruby, sem ERB), Hotwire (Turbo + Stimulus), Tailwind v4
- **Jobs / Cache / Cable**: Solid Queue + Solid Cache + Solid Cable — padrão Rails 8, sem Redis
- **Tenancy**: row-level (`tenant_id` em toda tabela de negócio), banco único, `acts_as_tenant`
- **Testes**: RSpec + FactoryBot, SimpleCov 100% desde o primeiro commit
- **Deploy**: Kamal

## Como rodar

Ambiente via Docker Compose (`app` + `db`, Postgres 16, sem Redis).

```bash
cp .env.example .env
docker compose up                                    # sobe app (bin/dev: Puma + Tailwind watch) + db
docker compose run --rm app bin/rails db:create db:migrate
```

## Comandos úteis

```bash
docker compose run --rm app bin/rails console
docker compose run --rm app bundle exec rspec        # suíte completa
docker compose run --rm app bundle exec rubocop
docker compose run --rm app bundle install            # após alterar o Gemfile
```

## Documentação

Guia completo para desenvolvimento (arquitetura, regras críticas, convenções de código e specs, fluxo de trabalho) em [`CLAUDE.md`](./CLAUDE.md). Decisões de arquitetura (ADRs) e demais artefatos vivem no vault Obsidian do projeto.
