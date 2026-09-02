class Views::Pages::Home::Features < Views::Base
  FEATURES = [
    [ "Agenda aberta 24 horas", "O cliente marca de madrugada, no domingo, no meio do seu atendimento. Você não precisa responder para não perder a reserva." ],
    [ "Confirmação e lembrete automáticos", "Confirmação na hora da reserva e lembrete antes do horário: as duas mensagens que mais reduzem falta. O envio por WhatsApp está em desenvolvimento." ],
    [ "Vários profissionais, uma agenda", "Cada pessoa da equipe tem seus serviços, seus horários e sua própria visão da agenda. O cliente escolhe com quem quer ser atendido." ],
    [ "Faturamento e ocupação do dia", "O painel é desenhado para responder quanto entrou, quantos horários ficaram vazios e quantos clientes novos apareceram — sem planilha paralela." ],
    [ "Funciona como app no celular", "Seu cliente adiciona o link na tela inicial e ele abre como aplicativo. Nada para baixar em loja, nada para aprovar." ],
    [ "Seus dados são só seus", "Cada estabelecimento é isolado no banco. Sua lista de clientes não circula e não é compartilhada com ninguém." ]
  ].freeze

  def view_template
    section(id: "recursos", class: "scroll-mt-16 border-b border-line bg-surface-2") do
      div(class: "mx-auto w-full max-w-6xl px-6 py-20") do
        h2(class: "mb-11 max-w-2xl text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl") do
          "O que a agenda passa a fazer sozinha"
        end
        div(class: "grid gap-6 sm:grid-cols-2 lg:grid-cols-3") { FEATURES.each { |title, body| render_feature(title, body) } }
      end
    end
  end

  private

  def render_feature(title, body)
    div(class: "grid content-start gap-2 rounded-2xl border border-line bg-surface p-6 shadow-sm") do
      h3(class: "text-base font-bold tracking-tight text-ink") { title }
      p(class: "text-sm leading-relaxed text-ink-muted") { body }
    end
  end
end
