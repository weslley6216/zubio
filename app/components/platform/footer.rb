class Components::Platform::Footer < Components::Base
  def initialize(links: [])
    @links = links
  end

  def view_template
    footer(class: "border-t border-line bg-surface") do
      div(class: "mx-auto flex w-full max-w-6xl flex-wrap items-center gap-4 px-6 py-8") do
        div(class: "flex items-center gap-2 text-sm text-ink-muted") do
          span(class: "grid h-7 w-7 place-items-center rounded-lg bg-brand-accent text-xs font-extrabold text-on-brand-accent") { "z" }
          span { "Zubio · agendamento online para o seu negócio" }
        end
        render_nav if @links.any?
      end
    end
  end

  private

  def render_nav
    nav(class: "ml-auto flex gap-5 text-sm font-semibold text-ink-muted") do
      @links.each { |label, anchor| a(href: anchor, class: "hover:text-ink") { label } }
    end
  end
end
