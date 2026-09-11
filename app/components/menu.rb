class Components::Menu < Components::Base
  LABEL = "Abrir menu".freeze
  ITEM_CLASS = "rounded-lg px-3 py-3 text-sm font-semibold".freeze
  CURRENT_CLASS = "bg-secondary-accent text-on-secondary-accent".freeze
  RESTING_CLASS = "text-ink hover:bg-surface-2".freeze

  def initialize(items:)
    @items = items
  end

  def view_template(&extra)
    details(class: "relative sm:hidden") do
      render_summary
      div(class: "absolute right-0 top-full z-30 mt-2 grid w-56 gap-1 rounded-xl border border-line bg-surface p-2 shadow-lg") do
        @items.each { |label, href, current| render_item(label, href, current) }
        yield(self) if extra
        render_theme_row
      end
    end
  end

  private

  def render_summary
    summary(class: "grid h-11 w-11 cursor-pointer list-none place-items-center rounded-lg border border-line bg-surface hover:bg-surface-2 [&::-webkit-details-marker]:hidden") do
      span(class: "sr-only") { LABEL }
      render_bars
    end
  end

  def render_item(label, href, current)
    a(href: href, aria_current: current ? "page" : nil,
      class: "#{ITEM_CLASS} #{current ? CURRENT_CLASS : RESTING_CLASS}") { label }
  end

  def render_theme_row
    button(
      type: "button",
      class: "flex cursor-pointer items-center gap-3 rounded-lg border-t border-line px-3 py-3 text-left text-sm font-semibold text-ink hover:bg-surface-2",
      data: { action: "theme#toggle" }
    ) do
      render Components::ContrastMark.new
      plain Components::ThemeToggle::LABEL
    end
  end

  def render_bars
    div(class: "grid gap-1") do
      3.times { span(class: "block h-0.5 w-4 rounded-full bg-ink") }
    end
  end
end
