class Components::Owner::Menu < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  LABEL = "Abrir menu".freeze
  ITEM_CLASS = "flex items-center gap-3 px-4 py-3.5 text-[14px] leading-[normal]".freeze
  CURRENT_CLASS = "bg-brand-soft text-brand-soft-ink font-extrabold".freeze
  RESTING_CLASS = "font-bold text-ink hover:bg-surface-2".freeze

  def initialize(items:)
    @items = items
  end

  def view_template
    details(class: "group relative lg:hidden", data: { owner_menu: true, controller: "owner-menu", action: "click@window->owner-menu#closeOutside" }) do
      render_summary
      div(class: "absolute -right-1.5 top-full z-30 mt-1 w-[262px] divide-y divide-line overflow-hidden rounded-[14px] border border-line bg-surface shadow-[0_16px_40px_rgba(14,26,36,0.18)]") do
        @items.each { |label, href, current, icon| render_item(label, href, current, icon) }
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
      render Components::Icon.new(:menu, class: "h-5 w-5")
    end
  end

  def render_item(label, href, current, icon)
    a(href: href, aria_current: current ? "page" : nil, class: "#{ITEM_CLASS} #{current ? CURRENT_CLASS : RESTING_CLASS}") do
      render_icon(icon, current)
      span(class: "flex-grow") { label }
      render_chevron if current
    end
  end

  def render_icon(icon, current)
    render Components::Icon.new(icon, class: "h-[18px] w-[18px] flex-none #{current ? "text-brand-600" : "text-ink-muted"}")
  end

  def render_chevron
    render Components::Icon.new(:chevron_right, stroke_width: "2.5", class: "h-4 w-4 flex-none text-brand-600")
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
    render Components::Icon.new(:log_out, class: "h-[18px] w-[18px] flex-none text-ink-muted")
  end
end
