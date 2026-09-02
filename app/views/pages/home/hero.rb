class Views::Pages::Home::Hero < Views::Base
  def view_template(&block)
    section(class: "border-b border-line") do
      div(class: "mx-auto grid w-full max-w-6xl gap-14 px-6 pb-20 pt-12 lg:grid-cols-2 lg:items-center lg:pt-20") do
        div(class: "grid gap-6") do
          render_eyebrow
          render_headline
          render_subhead
          render_actions
          render_subdomain_hint
        end
        block&.call
      end
    end
  end

  private

  def render_eyebrow
    span(class: "justify-self-start rounded-full bg-brand-100 px-3.5 py-1.5 text-xs font-extrabold tracking-wide text-brand-800") do
      "Salão, barbearia, estética, consultório"
    end
  end

  def render_headline
    h1(class: "text-4xl font-extrabold leading-none tracking-tighter text-ink sm:text-5xl lg:text-6xl") do
      plain "O cliente marca"
      br
      plain "sozinho."
      br
      span(class: "text-brand-accent") { "Você só atende." }
    end
  end

  def render_subhead
    p(class: "max-w-xl text-lg leading-relaxed text-ink-muted") do
      "O Zubio dá ao seu negócio uma página de agendamento com o seu nome e a sua cor. Você manda o link no WhatsApp, põe na bio do Instagram — e para de anotar horário no meio do atendimento."
    end
  end

  def render_actions
    div(class: "grid gap-3 sm:flex sm:flex-wrap sm:items-center") do
      a(href: new_signup_path, id: "hero-cta", class: "rounded-xl bg-brand-accent px-7 py-4 text-center text-base font-bold text-on-brand-accent shadow-md hover:opacity-90") do
        "Criar minha agenda grátis"
      end
      a(href: "#como", class: "rounded-xl border border-line-strong bg-surface px-6 py-4 text-center text-base font-bold text-ink hover:bg-surface-2") do
        "Ver como funciona"
      end
    end
  end

  def render_subdomain_hint
    div(class: "justify-self-start rounded-lg border border-dashed border-line-strong bg-surface px-4 py-3 text-sm font-semibold text-ink-muted") do
      span { "seusalao" }
      span(class: "text-ink") { ".zubio.com.br" }
      plain " — pronto no cadastro"
    end
  end
end
