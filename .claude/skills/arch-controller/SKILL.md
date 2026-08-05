---
name: arch-controller
description: Use when creating, altering, or reviewing a Rails controller in Zubio — namespaced by persona (Admin, Owner, Professional, Client). Use for BaseController per namespace, tenant resolution, authorization, and keeping actions thin (no business logic). NOT for model logic (arch-model) or Phlex rendering details (arch-view).
---

# Skill: Controllers namespaced por persona

## Propósito

Referência de como o Zubio organiza a camada de **orquestração HTTP**. Sem service layer ([[ADR-006 MVC sem camada de service]]), o controller é **fino por natureza**: params → chamada de método de model → redirect/render. Nenhuma outra responsabilidade.

Ainda não existe nenhum controller real além do que o `rails new` gerou (harness inicial). Este documento fixa o que já está decidido em ADR; o primeiro `BaseController` real e a primeira action real viram os exemplares canônicos.

## Quando usar

- Vou criar/alterar/revisar um controller ou action.
- Estou em dúvida se uma lógica pertence ao controller ou ao model.
- Preciso decidir onde fica autenticação/autorização de uma persona.

## Estrutura obrigatória (ver [[ADR-007 Controllers namespaced por persona]])

```
app/controllers/
  admin/          # Super-Admin — BaseController próprio
  owner/          # Dono do Estabelecimento — BaseController próprio
  professional/   # Profissional — BaseController próprio
  client/         # Cliente Final — BaseController próprio
```

Cada `<Namespace>::BaseController < ApplicationController` concentra a autenticação/autorização daquele grupo. Só sobe para `ApplicationController` o que é genuinamente comum aos 4 (ex: resolução de tenant por subdomínio) — não duplicação de conveniência, duplicação estrutural é esperada entre os 4 `BaseController`.

## Convenções essenciais

| Aspecto | Regra |
|---------|-------|
| Autenticação | `User` com senha para Admin/Owner/Professional; `Client` com OTP sem senha, sessão desacoplada — nunca misturar os dois sistemas no mesmo controller (ver [[ADR-008 Autenticação dupla User e Client]]) |
| Tenant | Resolvido sempre pelo host da requisição (subdomínio), nunca por parâmetro vindo do usuário |
| Action | Só params, chamada a método de model, redirect/render. Nada de query direta, cálculo de negócio ou orquestração de múltiplos models na action |
| Autorização | No `BaseController` do namespace via `before_action`, não checagem inline (`if current_user.admin?`) espalhada pelas actions |
| Sem service | Se uma action parece precisar de mais de uma chamada coordenada a models diferentes, é sinal do gatilho 1 do [[ADR-006 MVC sem camada de service]] — parar e revisar, não empilhar lógica na action |

## Arquivos desta skill

- **`template.rb`** — esqueleto de `BaseController` de namespace + controller filho.

## Fluxo sugerido

1. **Criar**: confirme o namespace correto (persona) antes de criar o arquivo. Parta de `template.rb`.
2. **Revisar**: rode a seção "O que analisar" dos itens Segurança, Rails Way e Model vs Controller do [[Checklist de Revisão]] contra o controller.
