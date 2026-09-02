class Views::Pages::Home::HowItWorks < Views::Base
  STEPS = [
    [ "1", "Você cadastra o negócio", "Nome, endereço e a cor da sua marca. Na mesma hora seu link já está no ar: seusalao.zubio.com.br." ],
    [ "2", "Você diz o que faz e quando atende", "Serviço, preço, duração e quem atende cada um. O Zubio monta os encaixes e nunca oferece um horário que já está ocupado." ],
    [ "3", "Você manda o link", "Na bio do Instagram, no WhatsApp, no cartão. O cliente escolhe sozinho e você só recebe o aviso." ]
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
      p(class: "text-lg text-ink-muted") { "Não tem instalação, não tem curso, não tem passar o caderno a limpo. São três passos." }
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
