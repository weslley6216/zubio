class Views::Pages::Home::SiteHeader < Views::Base
  LINKS = [
    [ "Recursos", "#recursos" ],
    [ "Como funciona", "#como" ],
    [ "Whitelabel", "#whitelabel" ],
    [ "Perguntas", "#faq" ]
  ].freeze

  def view_template
    header(class: "sticky top-0 z-20 border-b border-line bg-surface/90 backdrop-blur") do
      div(class: "mx-auto flex h-16 w-full max-w-6xl items-center gap-8 px-6") do
        render_wordmark
        render_nav
        render_actions
      end
    end
  end

  private

  def render_wordmark
    a(href: root_path, class: "flex items-center gap-2 font-extrabold tracking-tight text-ink") do
      span(class: "grid h-8 w-8 place-items-center rounded-lg bg-brand-accent text-on-brand-accent") { "z" }
      span { "Zubio" }
    end
  end

  def render_nav
    nav(class: "ml-auto hidden items-center gap-7 text-sm font-semibold sm:flex") do
      LINKS.each do |label, anchor|
        a(href: anchor, class: "text-ink-muted hover:text-ink") { label }
      end
    end
  end

  def render_actions
    div(class: "ml-auto flex items-center gap-3 sm:ml-0") do
      a(href: new_owner_session_path, class: "px-1 py-2 text-sm font-bold text-ink") { "Entrar" }
      a(href: new_signup_path, class: "rounded-lg bg-brand-accent px-4 py-2.5 text-sm font-bold text-on-brand-accent shadow-sm") { "Criar conta grátis" }
    end
  end
end
