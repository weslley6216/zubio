class Components::Service::Card < Components::Base
  CARD_CLASS = "relative flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5 shadow-[0_1px_2px_rgba(14,26,36,0.04)] hover:bg-surface-2".freeze
  DISABLED_CARD_CLASS = "relative flex items-center gap-3 rounded-xl border border-dashed border-line-strong bg-surface-2 px-4 py-3.5".freeze
  IDENTITY_CLASS = "grid min-w-0 grow gap-1".freeze
  NAME_ROW_CLASS = "flex flex-wrap items-center gap-2".freeze
  NAME_CLASS = "text-sm leading-[normal] font-bold text-ink after:absolute after:inset-0 after:rounded-xl".freeze
  DISABLED_NAME_CLASS = "text-sm leading-[normal] font-bold text-ink-muted after:absolute after:inset-0 after:rounded-xl".freeze
  DESCRIPTION_CLASS = "text-xs leading-[normal] text-ink-muted".freeze
  DURATION_ROW_CLASS = "mt-0.5 flex items-center gap-[5px]".freeze
  DURATION_CLASS = "text-xs leading-[normal] font-semibold tabular-nums text-ink-muted".freeze
  DISABLED_DURATION_CLASS = "text-xs leading-[normal] font-semibold tabular-nums text-ink-subtle".freeze

  SHOWCASE_CARD_CLASS = "relative flex items-center gap-3 rounded-[14px] border border-line bg-surface p-4 shadow-[0_1px_3px_rgba(14,26,36,0.05)]".freeze
  SHOWCASE_IDENTITY_CLASS = "grid min-w-0 grow gap-1".freeze
  SHOWCASE_NAME_CLASS = "text-[15px] leading-[normal] font-bold text-ink after:absolute after:inset-0 after:rounded-[14px]".freeze
  SHOWCASE_ASIDE_CLASS = "flex flex-none flex-col items-end gap-2".freeze
  CLOCK_ICON_CLASS = "h-[13px] w-[13px] flex-none text-ink-subtle".freeze
  CHEVRON_ICON_CLASS = "h-5 w-5 flex-none text-brand-600".freeze

  def initialize(service:, href:, variant: :panel, badges: [], description: nil)
    @service = service
    @href = href
    @variant = variant
    @badges = badges
    @description = description
  end

  def view_template
    if @variant == :showcase
      li(class: SHOWCASE_CARD_CLASS) do
        div(class: SHOWCASE_IDENTITY_CLASS) do
          a(href: @href, class: SHOWCASE_NAME_CLASS) { @service.name }
          render_description
          render_duration(DURATION_CLASS)
        end
        div(class: SHOWCASE_ASIDE_CLASS) do
          yield if block_given?
          render_chevron_icon
        end
      end
    else
      li(class: active? ? CARD_CLASS : DISABLED_CARD_CLASS) do
        div(class: IDENTITY_CLASS) do
          if @badges.any?
            div(class: NAME_ROW_CLASS) do
              render_panel_name
              @badges.each { |badge| render badge }
            end
          else
            render_panel_name
          end
          render_description
          render_duration(active? ? DURATION_CLASS : DISABLED_DURATION_CLASS)
        end
        yield if block_given?
      end
    end
  end

  private

  def active? = @service.active?

  def render_panel_name
    a(href: @href, class: active? ? NAME_CLASS : DISABLED_NAME_CLASS) { @service.name }
  end

  def render_description
    span(class: DESCRIPTION_CLASS, data: { description: true }) { @description } if @description.present?
  end

  def render_duration(duration_class)
    div(class: DURATION_ROW_CLASS) do
      render_clock_icon
      span(class: duration_class) { ::Service::Duration.minutes_label(@service.duration_minutes) }
    end
  end

  def render_clock_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: CLOCK_ICON_CLASS) do |icon|
      icon.circle(cx: "12", cy: "12", r: "9")
      icon.path(d: "M12 7v5l3 2")
    end
  end

  def render_chevron_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: CHEVRON_ICON_CLASS) do |icon|
      icon.path(d: "m9 6 6 6-6 6")
    end
  end
end
