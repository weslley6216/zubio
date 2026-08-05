# Zubio — Guia para Claude Code

## O que é o projeto

SaaS de agendamentos online, multi-tenant e whitelabel, para salões, barbearias e profissionais autônomos (psicólogos etc.). Subdomínio por tenant (`<estabelecimento>.zubio.com.br`). PWA servido pelo próprio Rails.

## Stack

- **Backend**: Ruby 4.0.1, Rails 8.1, PostgreSQL
- **Frontend**: Phlex (componentes Ruby, sem ERB), Hotwire (Turbo + Stimulus), Tailwind v4 (`@theme inline`)
- **Jobs / Cache / Cable**: Solid Queue + Solid Cache + Solid Cable — padrão Rails 8, **sem Redis**
- **Tenancy**: row-level (`tenant_id` em toda tabela de negócio), banco único, `acts_as_tenant`
- **Testes**: RSpec + FactoryBot, SimpleCov 100% desde o primeiro commit
- **Deploy**: Kamal (gerado pelo `rails new`, ainda não configurado)

Decisões completas e o porquê de cada uma: ADRs em `01-Arquitetura/ADR/` do vault Obsidian (ver Documentação completa).

## Comandos essenciais

Ainda não há Docker Compose neste repo — os comandos rodam direto:

```bash
bin/rails server            # sobe o app (ou bin/dev, que já roda Tailwind watch + Puma via Procfile.dev)
bin/rails console
bin/rails db:create db:migrate
bundle exec rspec           # suíte completa
bundle exec rubocop
```

Postgres precisa estar acessível via `config/database.yml` (hoje aponta para localhost). Setup de Docker Compose para Postgres, gems de teste (RSpec/FactoryBot/SimpleCov) e CI ainda estão pendentes — checklist de execução em `01-Arquitetura/Handoff — Setup de Infra Local.md` do vault.

## Arquitetura em uma linha

`Controller → Model → DB`, sem camada de service — ver [[ADR-006 MVC sem camada de service]]. Views Phlex renderizam o que o model/controller já preparou.

## Regras críticas

- **Sem camada de service no harness inicial**: lógica de negócio mora em Model (validação, scope, cálculo sobre o próprio estado) ou Controller (fino: params, chamada de método de model, redirect). Os dois gatilhos para revisitar essa decisão — (1) um método de model precisa orquestrar 2+ models fora das próprias associações, (2) a mesma lógica se repete em 2+ controllers — estão em [[ADR-006 MVC sem camada de service]]. Quando um deles aparecer de verdade, a escolha do padrão é feita com informação real, não adiantada aqui.
- **Colisão de nome a vigiar**: o domínio tem um substantivo de negócio "serviço" (o que o estabelecimento oferece — corte, sessão) sem relação com "service object". `app/models/service.rb` é válido; `app/services/` não deve existir.
- **Toda tabela de negócio tem `tenant_id`, todo model correspondente declara `acts_as_tenant`.** Nenhuma query em model com `tenant_id` pode rodar sem o escopo do tenant atual. Todo background job recebe `tenant_id` explícito e reabre o escopo dentro do `perform` — nunca herda do momento de enfileiramento. Toda chave de cache é prefixada por tenant.
- **Resolução de tenant é sempre pelo host da requisição**, nunca por parâmetro vindo do usuário.
- **Todo valor de estilo do whitelabel vindo do banco passa por allowlist antes de virar CSS custom property** — ver [[ADR-004 Whitelabel por CSS custom properties]].
- **`users` (autenticação) é separado de `professionals` (agenda)** — `professionals.user_id` é nullable. Agendamento referencia `professional_id`, nunca `user_id`. Ver [[ADR-002 Separação Usuário x Profissional]].
- **Autenticação dupla**: `User` com senha (Admin/Owner/Professional) e `Client` com OTP sem senha, sessões desacopladas — não confundir os dois sistemas no mesmo código. Ver [[ADR-008 Autenticação dupla User e Client]].
- **Controllers namespaced por persona desde o primeiro commit**: `app/controllers/{admin,owner,professional,client}/`, cada namespace com seu próprio `BaseController`. Ver [[ADR-007 Controllers namespaced por persona]].
- **Phlex, não ERB**: views são arquivos `.rb`.
- **Cobertura 100%**: SimpleCov bloqueia se cair. Toda linha nova precisa de spec.

Checklist completo (13 princípios, o que analisar em cada revisão): [[Checklist de Revisão]].

## Convenções de código

- **Sem comentários em `.rb`** salvo para justificar o não óbvio (constraint escondida, workaround específico) — nunca para explicar o quê.
- **Sem variáveis de bloco de uma letra**: usar o nome do domínio (`|appointment|`, `|professional|`).
- **Idiomas**: código, commits e símbolos Ruby em inglês; comunicação humana (docs, ADRs) em pt-BR.

## Convenções de specs (RSpec)

- **Sem `let!`**: usar `let` + referência explícita, ou `create` dentro do `it`.
- **AAA com linha vazia** entre Arrange/Act/Assert quando as três fases estão no `it`. Nunca comentários no spec.
- **Sem `expect_any_instance_of`/`allow_any_instance_of`**: mockar classe/instância específica.
- **Teste só-negativo exige par positivo discriminante** — exceção: isolamento entre tenants (`not_to include` de dado de outro tenant sempre tem par: "inclui o do próprio tenant").
- **Todo spec de model/controller que toca dado escopado por tenant precisa de um caso de isolamento entre tenants.**

Detalhamento e *shape* de spec por camada: skill `arch-spec`.

## Fluxo de trabalho e git

- **`/discovery NN` → `/plan NN` → `/execute NN` → `/ship`** — skills locais deste repo (`.claude/skills/`, não versionadas, exceto `arch-*`). Gates de qualidade do `/ship` substituem revisão de PR: um único OK humano, depois `git merge --no-ff` na main + push.
- **Commits**: em inglês, Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`), **sem `Co-authored-by`**.
- Artefatos do fluxo no vault Obsidian (`~/Obsidian/Zubio/`), nunca em `docs/` deste repo.

## Documentação completa

Vault Obsidian em `~/Obsidian/Zubio/` — decisões de arquitetura e ADRs em `01-Arquitetura/`, checklist de revisão em `01-Arquitetura/Checklist de Revisão.md`, convenções do vault em `00-Meta/Convenções.md`, escopo de release em `90-Releases/`.
