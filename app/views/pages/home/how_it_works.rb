class Views::Pages::Home::HowItWorks < Views::Base
  STEPS = [
    [ "1", "Cadastre seu negócio", "Nome, endereço e sua cor. Na mesma hora você recebe o endereço próprio seusalao.zubio.com.br." ],
    [ "2", "Monte serviços e horários", "Preço, duração e quem atende cada serviço. O Zubio calcula os encaixes possíveis e nunca oferece um horário ocupado." ],
    [ "3", "Compartilhe o link", "Na bio do Instagram, no WhatsApp, no cartão. O cliente marca sozinho e você só recebe a confirmação." ]
  ].freeze

  def view_template
    section(id: "como", class: "scroll-mt-16 border-b border-line") do
      div(class: "mx-auto w-full max-w-6xl px-6 py-20") do
        render_intro
        div(class: "grid gap-8 sm:grid-cols-3") { STEPS.each { |number, title, body| render_step(number, title, body) } }
      end
    end
  end

  private

  def render_intro
    div(class: "mb-11 grid max-w-2xl gap-3") do
      span(class: "text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-brand-accent") { "Como funciona" }
      h2(class: "text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl") { "Do cadastro ao primeiro agendamento" }
      p(class: "text-lg text-ink-muted") { "Sem instalação, sem migração de dados, sem treinamento. Três passos e sua agenda está no ar." }
    end
  end

  def render_step(number, title, body)
    div(class: "grid content-start gap-3") do
      span(class: "grid h-9 w-9 place-items-center rounded-full bg-brand-100 text-sm font-extrabold text-brand-800") { number }
      h3(class: "text-lg font-bold tracking-tight text-ink") { title }
      p(class: "text-sm leading-relaxed text-ink-muted") { body }
    end
  end
end
