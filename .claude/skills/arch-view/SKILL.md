---
name: arch-view
description: Use when creating, altering, or reviewing a Phlex view/component in Zubio. Use for view_template structure, receiving data instead of querying the DB, and applying whitelabel CSS custom properties safely. NOT for controller logic (arch-controller) or model logic (arch-model).
---

# Skill: Views Phlex

## Propósito

Referência de como o Zubio renderiza. Views são **sempre Phlex** (`.rb`), nunca ERB — decisão de stack, não deste ADR específico (ver [[index]]).

Ainda não existe nenhuma view real além do layout gerado pelo `rails new` (harness inicial). O split entre `app/components/` (peças reutilizáveis) e `app/views/` (páginas/respostas) não está fixado ainda — decida na primeira tela real e registre aqui. Este documento cobre só o que já é regra hoje.

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
