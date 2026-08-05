---
name: arch-model
description: Use when creating, altering, or reviewing an ActiveRecord model in Zubio — a class inheriting from ApplicationRecord (Tenant, User, Professional, Service, Appointment, etc). Use for tenant_id/acts_as_tenant, enums, validates, associations, scopes, and the Model vs Controller boundary. NOT for controller actions (arch-controller) or Phlex views (arch-view).
---

# Skill: Models ActiveRecord

## Propósito

Referência de como o Zubio modela a camada de **persistência**. Zubio não tem camada de service ([[ADR-006 MVC sem camada de service]]) — o model é dono de mais responsabilidade do que num projeto com services: persistência **e** invariante de negócio que dependa só do próprio estado.

Ainda não existe nenhum model real no código (harness inicial, ver [[ADR-009 Checklist de qualidade e skills locais]]). Este documento fixa as convenções já decididas em ADR; a primeira classe real desta camada vira o exemplar canônico — atualize este arquivo quando ela existir.

## Quando usar

- Vou criar/alterar/revisar um model AR ou seu spec.
- Estou em dúvida se uma lógica vai no **model** ou no **controller** (não há terceira opção — sem service).
- Preciso decidir sobre `tenant_id`/`acts_as_tenant`, enum, associação, scope ou validação.

## Model ou controller (a decisão que erra fácil)

Sem camada de service, tudo que não é "params → chamada → redirect" é candidato a model. Ver item 13 do [[Checklist de Revisão]] para a régua completa e os dois gatilhos que reabririam a discussão de uma camada nova.

| Se… | Vai para |
|-----|----------|
| Persiste, mapeia tabela, tem enum/validação/associação/scope | Model — `app/models/<singular>.rb` |
| Deriva do **próprio estado já carregado** (predicado, cálculo de 1 passo) | Método no model |
| Orquestra 2+ models fora de associação, ou se repete em 2+ controllers | **Gatilho atingido** — parar e discutir camada nova, não decidir sozinho (ver [[ADR-006 MVC sem camada de service]]) |

## Convenções essenciais

| Aspecto | Regra |
|---------|-------|
| Arquivo / classe | `app/models/<singular>.rb`; `class Professional < ApplicationRecord` — singular, top-level |
| Tenancy | Toda tabela de negócio (exceto `tenants`) tem `tenant_id`; todo model correspondente declara `acts_as_tenant` — sem exceção, é invariante do sistema (ver [[index]]) |
| Colisão de nome | `Service` é um model de domínio válido (o que o estabelecimento oferece) — não confundir com "service object", que não existe neste projeto |
| `users` vs `professionals` | Não misturar autenticação com agenda — `professionals.user_id` é nullable, agendamento referencia `professional_id`, nunca `user_id` (ver [[ADR-002 Separação Usuário x Profissional]]) |
| Limite de negócio | Constante do model (`MAX_*`/`MIN_*`) + `validates` correspondente — o model é dono do invariante |
| Associações | `belongs_to`/`has_many`/`has_one` sempre com `dependent:` explícito |
| Scopes | Lambda chainable, componível; nunca lógica de apresentação |
| Validação cross-field | `validate :metodo` privado; `errors.add(:campo, :chave_i18n)` — símbolo, nunca string literal |
| Spec | FactoryBot (`build`/`create`); todo model com `tenant_id` tem caso de isolamento entre tenants — regras gerais em `arch-spec` |

## Arquivos desta skill

- **`template.rb`** — esqueleto para iniciar um model AR com tenancy.

## Fluxo sugerido

1. **Criar**: confirme na tabela acima que é mesmo lógica de model (não controller, não um dos dois gatilhos de camada nova). Parta de `template.rb`, ajuste tabela/enums/associações. Crie o spec com FactoryBot incluindo o caso de isolamento entre tenants.
2. **Alterar**: mude enum/validação/associação/scope e atualize o spec e a factory na mesma mudança.
3. **Revisar**: rode a seção "O que analisar" dos itens SRP, DRY, YAGNI, Segurança e Model vs Controller do [[Checklist de Revisão]] contra o model e o spec.
