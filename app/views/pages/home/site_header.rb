class Views::Pages::Home::SiteHeader < Views::Base
  LINKS = [
    [ "Como funciona", "#como" ],
    [ "O que muda", "#recursos" ],
    [ "Sua marca", "#whitelabel" ],
    [ "Perguntas", "#faq" ]
  ].freeze
  TOGGLE_LABEL = "Trocar o tema"

  def view_template
    header(class: "sticky top-0 z-20 border-b border-line bg-surface/90 backdrop-blur", data: { controller: "theme" }) do
      div(class: "mx-auto flex h-16 w-full max-w-6xl items-center gap-3 px-6 sm:gap-8") do
        render_wordmark
        render_nav
        render_actions
        render_mobile_menu
      end
    end
  end

  private

  def render_wordmark
    a(href: root_path, class: "flex min-h-11 items-center gap-2 font-extrabold tracking-tight text-ink") do
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
      render_theme_button
      a(href: new_owner_session_path, class: "hidden min-h-11 items-center rounded-lg px-2 text-sm font-bold text-ink hover:bg-surface-2 sm:inline-flex") { "Entrar" }
      a(href: new_signup_path, class: "inline-flex min-h-11 items-center rounded-lg bg-brand-accent px-4 text-sm font-bold text-on-brand-accent shadow-sm hover:opacity-90") { "Criar conta grátis" }
    end
  end

  def render_theme_button
    button(
      type: "button",
      class: "hidden h-11 w-11 cursor-pointer place-items-center rounded-lg border border-line bg-surface hover:bg-surface-2 sm:grid",
      title: TOGGLE_LABEL,
      aria_label: TOGGLE_LABEL,
      data: { action: "theme#toggle" }
    ) { render_contrast_mark }
  end

  def render_mobile_menu
    details(class: "relative sm:hidden") do
      summary(class: "grid h-11 w-11 cursor-pointer list-none place-items-center rounded-lg border border-line bg-surface hover:bg-surface-2 [&::-webkit-details-marker]:hidden") do
        span(class: "sr-only") { "Abrir menu" }
        render_menu_bars
      end
      div(class: "absolute right-0 top-full z-30 mt-2 grid w-56 gap-1 rounded-xl border border-line bg-surface p-2 shadow-lg") do
        LINKS.each { |label, anchor| a(href: anchor, class: "rounded-lg px-3 py-3 text-sm font-semibold text-ink hover:bg-surface-2") { label } }
        a(href: new_owner_session_path, class: "rounded-lg px-3 py-3 text-sm font-bold text-ink hover:bg-surface-2") { "Entrar" }
        render_theme_row
      end
    end
  end

  def render_theme_row
    button(
      type: "button",
      class: "flex cursor-pointer items-center gap-3 rounded-lg border-t border-line px-3 py-3 text-left text-sm font-semibold text-ink hover:bg-surface-2",
      data: { action: "theme#toggle" }
    ) do
      render_contrast_mark
      plain TOGGLE_LABEL
    end
  end

  def render_contrast_mark
    span(class: "relative block h-5 w-5 flex-none overflow-hidden rounded-full border-2 border-ink") do
      span(class: "absolute inset-y-0 left-0 w-1/2 bg-ink")
    end
  end

  def render_menu_bars
    div(class: "grid gap-1") do
      3.times { span(class: "block h-0.5 w-4 rounded-full bg-ink") }
    end
  end
end
