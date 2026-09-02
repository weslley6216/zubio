class Views::Pages::Home::Features < Views::Base
  FEATURES = [
    [ "Sua agenda fica aberta 24 horas", "O cliente marca de madrugada, no domingo, no meio do seu atendimento. Você não precisa parar para responder.", nil ],
    [ "Menos cliente que não aparece", "Confirmação na hora da reserva e lembrete antes do horário — as duas mensagens que mais reduzem falta.", "Envio por WhatsApp em breve" ],
    [ "A equipe toda na mesma agenda", "Cada profissional tem seus serviços, seus horários e a própria tela. O cliente escolhe com quem quer ser atendido.", nil ],
    [ "Você vê o dia num olhar", "Quanto entrou, quantos horários ficaram vazios, quantos clientes novos apareceram. Sem planilha por fora.", nil ],
    [ "Vira app no celular do cliente", "Ele salva o seu link na tela inicial e abre como aplicativo. Nada para baixar em loja.", nil ],
    [ "Sua lista de clientes é sua", "Ninguém mais enxerga os seus clientes, e não cobramos comissão por agendamento.", nil ]
  ].freeze

  def view_template
    section(id: "recursos", class: "scroll-mt-16 border-b border-line bg-surface-2") do
      div(class: "mx-auto w-full max-w-6xl px-6 py-20") do
        h2(class: "mb-11 max-w-2xl text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl") do
          "O que muda no seu dia"
        end
        div(class: "grid gap-6 sm:grid-cols-2 lg:grid-cols-3") { FEATURES.each { |title, body, tag| render_feature(title, body, tag) } }
      end
    end
  end

  private

  def render_feature(title, body, tag)
    div(class: "grid content-start gap-2 rounded-2xl border border-line bg-surface p-6 shadow-sm") do
      div(class: "flex flex-wrap items-center gap-2") do
        h3(class: "text-base font-bold tracking-tight text-ink") { title }
        render_tag(tag) if tag
      end
      p(class: "text-sm leading-relaxed text-ink-muted") { body }
    end
  end

  def render_tag(tag)
    span(class: "rounded-full bg-surface-3 px-2.5 py-1 text-[0.7rem] font-bold text-ink-muted") { tag }
  end
end
