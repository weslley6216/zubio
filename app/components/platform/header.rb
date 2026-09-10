class Components::Platform::Header < Components::Base
  def initialize(links: [], cta: nil)
    @links = links
    @cta = cta
  end

  def view_template
    header(class: "sticky top-0 z-20 border-b border-line bg-surface/90 backdrop-blur", data: { controller: "theme" }) do
      div(class: "mx-auto flex h-16 w-full max-w-6xl items-center gap-3 px-6 sm:gap-8") do
        render_wordmark
        render_nav if @links.any?
        render_actions
        render_mobile_menu if mobile_menu?
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
      @links.each do |label, anchor|
        a(href: anchor, class: "text-ink-muted hover:text-ink") { label }
      end
    end
  end

  def render_actions
    div(class: "ml-auto flex items-center gap-3 sm:ml-0") do
      render Components::ThemeToggle.new(hidden_on_phone: mobile_menu?)
      render_cta if @cta
    end
  end

  def render_cta
    text, href = @cta

    a(href: href, class: "inline-flex min-h-11 items-center rounded-lg bg-brand-accent px-4 text-sm font-bold text-on-brand-accent shadow-sm hover:opacity-90") { text }
  end

  def mobile_menu? = @links.any?

  def render_mobile_menu
    render Components::Menu.new(items: @links)
  end
end
