---
name: arch-view
description: Use when creating, altering, or reviewing a Phlex view/component in Zubio. Use for view_template structure, receiving data instead of querying the DB, and applying whitelabel CSS custom properties safely. NOT for controller logic (arch-controller) or model logic (arch-model).
---

# Skill: Views Phlex

## Propósito

Referência de como o Zubio renderiza. Views são **sempre Phlex** (`.rb`), nunca ERB — decisão de stack, não deste ADR específico (ver [[index]]).

## O split, fixado

`config/initializers/phlex.rb` registra dois autoload dirs, e a fronteira entre eles é a regra:

| Namespace | Diretório | O que mora ali | Base |
|-----------|-----------|----------------|------|
| `Components::` | `app/components/` | peça reutilizável, sem rota, sem layout — `Components::Panel`, `Components::Alert`, `Components::Form::Errors` | `Components::Base < Phlex::HTML` |
| `Views::` | `app/views/` | página ou resposta que um controller renderiza, e que monta o próprio documento | `Views::Base < Components::Base` |

`Views::Base` herda de `Components::Base`, então toda view tem os helpers de component mais `FormWith` e `Flash`. Uma peça que passa a ser usada por 2+ views sobe de `Views::` para `Components::`.

## Exemplares canônicos

| Papel | Classe |
|-------|--------|
| Layout que injeta o whitelabel | `Views::Layouts::Application` — `css_variables` sob `raw safe(...)`, valor já filtrado por `Branding::ColorScale` |
| Página composta por seções | `Views::Pages::Home` — orquestra `Views::Pages::Home::*`, cada seção um arquivo |
| Component com estado de tom | `Components::Signup::SubdomainStatus` — tom e mensagem no mesmo `STATES`, `fetch` com fallback |
| View de formulário | `Views::Owner::Brandings::Edit` — `form_with` + `Components::Form::Errors` por campo, classes de `Components::Form::Styles` |

## Quando usar

- Vou criar/alterar/revisar uma view ou component Phlex.
- Preciso renderizar algo que depende do tema/whitelabel do tenant.

## Convenções essenciais

| Aspecto | Regra |
|---------|-------|
| Base | `.rb`, herda de `Phlex::HTML` (ou base própria a definir quando a segunda view existir) |
| Dados | View recebe dado já pronto via argumento — nunca chama o model/banco direto de dentro de `view_template` |
| Whitelabel | Toda cor/token de tema vindo do tenant passa por allowlist de CSS custom property antes de virar estilo — nunca interpolar valor cru do banco em `style=` (ver [[index]] → Invariantes do sistema) |
| Responsabilidade | Decisão de negócio (ex: "mostrar preço ou não") é resolvida antes de chegar na view — a view só reflete o dado, não decide a regra |

## Fluxo sugerido

1. **Criar**: confirme que o dado a renderizar já vem pronto do controller/model, não vai ser buscado pela própria view.
2. **Revisar**: rode a seção "O que analisar" do item Phlex do [[Checklist de Revisão]] — atenção especial ao ponto de whitelabel/CSS, é o único risco de segurança específico desta camada.
