class Components::Owner::Menu < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  LABEL = "Abrir menu".freeze
  ITEM_CLASS = "flex items-center gap-3 px-4 py-3.5 text-sm".freeze
  CURRENT_CLASS = "bg-brand-soft text-brand-soft-ink font-extrabold".freeze
  RESTING_CLASS = "font-bold text-ink hover:bg-surface-2".freeze
  CHEVRON_PATH = "m9 6 6 6-6 6".freeze
  GEAR_PATH = "M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1 2 2 0 1 1-4 0 1.6 1.6 0 0 0-2.7-1.1l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.6 1.6 0 0 0 3 15a2 2 0 1 1 0-4 1.6 1.6 0 0 0 1.1-2.7l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 9 4.6a2 2 0 1 1 4 0 1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1A1.6 1.6 0 0 0 19.4 11a2 2 0 1 1 0 4z".freeze
  DOOR_PATH_1 = "M9 21H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3".freeze
  DOOR_PATH_2 = "m16 17 5-5-5-5M21 12H9".freeze
  HAMBURGER_PATH = "M4 7h16M4 12h16M4 17h16".freeze

  def initialize(items:)
    @items = items
  end

  def view_template
    details(class: "group relative sm:hidden") do
      render_summary
      div(class: "absolute right-0 top-full z-30 mt-2 w-64 divide-y divide-line overflow-hidden rounded-xl border border-line bg-surface shadow-lg") do
        @items.each { |label, href, current| render_item(label, href, current) }
        render_theme_row
        render_sign_out
      end
    end
  end

  private

  def render_summary
    summary(
      class: "grid h-11 w-11 cursor-pointer list-none place-items-center rounded-lg border border-line bg-surface text-ink group-open:border-brand-600 group-open:bg-brand-soft group-open:text-brand-600 [&::-webkit-details-marker]:hidden"
    ) do
      span(class: "sr-only") { LABEL }
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-5 w-5") { |icon| icon.path(d: HAMBURGER_PATH) }
    end
  end

  def render_item(label, href, current)
    a(href: href, aria_current: current ? "page" : nil, class: "#{ITEM_CLASS} #{current ? CURRENT_CLASS : RESTING_CLASS}") do
      render_gear(current)
      span(class: "flex-grow") { label }
      render_chevron if current
    end
  end

  def render_gear(current)
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-[18px] w-[18px] flex-none #{current ? "text-brand-600" : "text-ink-muted"}") do |icon|
      icon.circle(cx: "12", cy: "12", r: "3")
      icon.path(d: GEAR_PATH)
    end
  end

  def render_chevron
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-4 w-4 flex-none text-brand-600") { |icon| icon.path(d: CHEVRON_PATH) }
  end

  def render_theme_row
    button(type: "button", class: "#{ITEM_CLASS} #{RESTING_CLASS} w-full cursor-pointer text-left", data: { action: "theme#toggle" }) do
      render Components::ContrastMark.new
      span(class: "flex-grow") { Components::ThemeToggle::LABEL }
    end
  end

  def render_sign_out
    button_to(owner_session_path, method: :delete, class: "#{ITEM_CLASS} #{RESTING_CLASS} w-full cursor-pointer text-left") do
      render_door
      span(class: "flex-grow") { Components::Owner::Header::SIGN_OUT_LABEL }
    end
  end

  def render_door
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-[18px] w-[18px] flex-none text-ink-muted") do |icon|
      icon.path(d: DOOR_PATH_1)
      icon.path(d: DOOR_PATH_2)
    end
  end
end
