class Components::Service::Card < Components::Base
  CARD_CLASS = "relative flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5 hover:bg-surface-2".freeze
  IDENTITY_CLASS = "grid min-w-0 gap-0.5".freeze
  NAME_ROW_CLASS = "flex flex-wrap items-center gap-2".freeze
  NAME_CLASS = "text-sm font-bold text-ink after:absolute after:inset-0 after:rounded-xl".freeze
  DESCRIPTION_CLASS = "text-xs text-ink-muted".freeze
  DURATION_CLASS = "text-xs tabular-nums text-ink-muted".freeze

  def initialize(service:, href:, badges: [], description: nil)
    @service = service
    @href = href
    @badges = badges
    @description = description
  end

  def view_template
    li(class: CARD_CLASS) do
      div(class: IDENTITY_CLASS) do
        div(class: NAME_ROW_CLASS) do
          a(href: @href, class: NAME_CLASS) { @service.name }
          @badges.each { |badge| render badge }
        end
        span(class: DESCRIPTION_CLASS, data: { description: true }) { @description } if @description.present?
        span(class: DURATION_CLASS) { ::Service::Duration.label(@service.duration_minutes) }
      end
      yield if block_given?
    end
  end
end
