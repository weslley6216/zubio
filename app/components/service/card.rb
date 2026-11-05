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

  TILE_CARD_CLASS = "relative flex min-h-[120px] flex-col justify-between gap-2.5 rounded-2xl border border-(--theme-card-line) bg-(--theme-card) p-4 text-(--theme-on-card)".freeze
  TILE_NAME_CLASS = "text-[15px] leading-[1.3] font-extrabold text-pretty after:absolute after:inset-0 after:rounded-2xl".freeze
  TILE_ROW_CLASS = "flex items-baseline justify-between gap-1.5".freeze
  TILE_DURATION_CLASS = "text-[12px] text-(--theme-on-card-muted)".freeze
  TILE_DESCRIPTION_CLASS = "text-xs leading-[normal] text-(--theme-on-card-muted)".freeze
  CLOCK_ICON_CLASS = "h-[13px] w-[13px] flex-none text-ink-subtle".freeze

  def initialize(service:, href:, variant: :panel, badges: [], description: nil)
    @service = service
    @href = href
    @variant = variant
    @badges = badges
    @description = description
  end

  def view_template
    if @variant == :tile
      li(class: TILE_CARD_CLASS) do
        a(href: @href, class: TILE_NAME_CLASS) { @service.name }
        render_description(TILE_DESCRIPTION_CLASS)
        div(class: TILE_ROW_CLASS) do
          span(class: TILE_DURATION_CLASS) { ::Service::Duration.minutes_label(@service.duration_minutes) }
          yield if block_given?
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

  def render_description(description_class = DESCRIPTION_CLASS)
    span(class: description_class, data: { description: true }) { @description } if @description.present?
  end

  def render_duration(duration_class)
    div(class: DURATION_ROW_CLASS) do
      render_clock_icon
      span(class: duration_class) { ::Service::Duration.minutes_label(@service.duration_minutes) }
    end
  end

  def render_clock_icon
    render Components::Icon.new(:clock, class: CLOCK_ICON_CLASS)
  end
end
