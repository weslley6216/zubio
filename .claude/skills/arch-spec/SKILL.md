---
name: arch-spec
description: Use when writing or reviewing any RSpec spec in Zubio — shared conventions every layer's spec follows (no let!, AAA with blank line, no allow_any_instance_of, positive-pair rule, mandatory tenant-isolation case, FactoryBot). Layer-specific spec shape lives in arch-model and arch-controller.
---

# Skill: Specs (RSpec — base compartilhada)

## Propósito

Convenções de spec compartilhadas por todas as camadas do Zubio. Testes são RSpec + FactoryBot + SimpleCov com **cobertura 100% obrigatória** desde o primeiro commit.

## Quando usar

- Vou escrever/revisar um spec de qualquer camada (model, controller, view).
- Estou em dúvida sobre `let` vs `before`, AAA, mock, ou o caso de isolamento entre tenants.

## As regras da casa

| Regra | Detalhe |
|-------|---------|
| **Sem `let!`** | usar `let` + referência explícita, ou `create` dentro do `it` |
| **AAA com linha vazia** | linha em branco entre Arrange/Act/Assert quando as três fases estão no `it`; se arrange/act estão em `let`, o `it` só tem o Assert |
| **Nunca comentários** | nada de `# Arrange`, nem qualquer outro comentário no spec |
| **Sem `*_any_instance_of`** | proibido `allow_any_instance_of`/`expect_any_instance_of`; mockar classe/instância específica ou testar o comportamento resultante |
| **Sem referência a ACs** | o nome do exemplo descreve o comportamento e faz sentido sozinho |
| **Teste só-negativo exige par positivo** | exceção explícita: isolamento entre tenants (`not_to include` de dado de outro tenant sempre tem par — "inclui o do próprio tenant") |
| **Isolamento entre tenants é obrigatório, não opcional** | todo spec de model ou controller que toca um recurso com `tenant_id` precisa de um exemplo que prove que dado de outro tenant não vaza |
| **Sem var de bloco de 1 letra** | `|professional|` não `|p|` |
| **Construção** | FactoryBot (`build`/`create`) — factories em `spec/factories/<plural>.rb` |
| **shoulda-matchers** | reservado para o que é declaração e não comportamento: `have_many(...).dependent(...)`, `belong_to(...).optional`. Validação e regra de negócio continuam em exemplo explícito com FactoryBot, que falha dizendo o que quebrou |

## Tipo e diretório por camada

| Camada | Diretório | `type:` | Shape em |
|--------|-----------|---------|----------|
| Model | `spec/models/` | `:model` | **arch-model** |
| Controller | `spec/requests/` | `:request` | **arch-controller** |
| View/Component | `spec/components/` | `:component` | **arch-view** |
| System (e2e) | `spec/system/` | `:system` | esta seção |

## System specs (e2e)

Driver default é `rack_test` (config em `spec/support/capybara.rb`); a tag `js: true` troca para Cuprite (Chrome headless real via CDP) — só quando o teste precisa que CSS/JS realmente rode no browser (ex: token de whitelabel resolvido via `@theme inline`, comportamento de Stimulus/Turbo). Sem `:js`, fica em `rack_test` — mais barato, sem browser real.

- **Um spec de sistema por página/fluxo real, só o happy path.** Casos de borda (validação, isolamento entre tenants, variação de estado) continuam em model/request spec — mais barato e já prova a lógica; repetir a matriz de edge cases em Cuprite só paga custo de browser sem cobrir nada novo.
O *shape*, com os exemplares:

| Arquivo | Papel |
|---------|-------|
| `spec/system/signup_spec.rb` | um fluxo real, só o happy path — o modelo a copiar para uma tela nova |
| `spec/system/landing_spec.rb` | aparência de uma página: token pintado, contraste, alvo de toque, overflow |
| `spec/system/surface_spec.rb` | invariante que atravessa telas (tema persistido entre landing e app) — não pertence a nenhuma página só |
| `spec/system/health_check_spec.rb` | prova que os dois drivers sobem; não replicar por página |

Component spec renderiza direto (`described_class.new(...).call`) e assere sobre a string — ver `spec/components/theme_toggle_spec.rb`.

## Arquivos desta skill

- **`template.rb`** — esqueleto mínimo de um spec de model com caso de isolamento entre tenants.

## Fluxo sugerido

1. **Escrever**: use o *shape* da skill de camada + estas regras gerais. Parta de `template.rb`.
2. **Revisar**: rode o checklist acima; confirme cobertura 100% e presença do caso de isolamento entre tenants sempre que o recurso tiver `tenant_id`.
