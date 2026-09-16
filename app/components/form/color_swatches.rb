class Components::Form::ColorSwatches < Components::Base
  include Components::Form::Styles

  CUSTOM_SUMMARY = "+".freeze
  CUSTOM_CHOICE_LABEL = "Usar este código".freeze
  PICKER_LABEL = "Escolher a cor em um seletor".freeze
  CODE_LABEL = "Código hexadecimal da cor".freeze
  NONE_LABEL = "Sem".freeze
  ROW_SIZE = 5

  FILLS = { brand_600: "bg-brand-600", brand_secondary_600: "bg-secondary-600" }.freeze

  LEGEND_CLASS = "flex w-full items-baseline gap-1.5 text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  TAG_CLASS = "ml-auto normal-case".freeze
  ROW_CLASS = "mt-1.5 flex flex-wrap items-center gap-2".freeze
  ROW_OPTION_CLASS = "flex-1 basis-0".freeze
  SWATCH_CLASS = "block h-11 w-full rounded-lg ring-1 ring-line peer-checked:ring-2 peer-checked:ring-ink peer-checked:ring-offset-2 peer-checked:ring-offset-surface".freeze
  NONE_CLASS = "flex h-11 w-full items-center justify-center rounded-lg text-xs font-bold text-ink-muted ring-1 ring-line peer-checked:ring-2 peer-checked:ring-ink".freeze
  DETAILS_CLASS = "contents".freeze
  SUMMARY_CLASS = "grid h-11 w-11 flex-none cursor-pointer list-none place-items-center rounded-lg text-lg font-bold text-ink-muted ring-1 ring-line [&::-webkit-details-marker]:hidden".freeze
  GRID_CLASS = "mt-2 grid w-full basis-full grid-cols-8 gap-2".freeze
  GRID_OPTION_CLASS = "block".freeze
  GRID_SWATCH_CLASS = "block aspect-square rounded-lg ring-1 ring-line peer-checked:ring-2 peer-checked:ring-ink peer-checked:ring-offset-2 peer-checked:ring-offset-surface".freeze
  CUSTOM_PANEL_CLASS = "mt-2 flex w-full basis-full items-end gap-2".freeze
  CUSTOM_CHOICE_CLASS = "inline-flex min-h-11 flex-none items-center gap-2 text-sm text-ink".freeze
  PICKER_CLASS = "h-11 w-11 flex-none cursor-pointer rounded-lg border border-line".freeze

  def initialize(label:, hint:, attribute:, selected:, fallback: Branding::DEFAULT_BRAND_600, tag: nil)
    @label = label
    @hint = hint
    @attribute = attribute
    @selected = selected
    @fallback = fallback
    @tag = tag
  end

  def view_template
    fieldset(aria_label: @label) do
      legend(class: LEGEND_CLASS) do
        span { @label }
        span(aria_hidden: "true") { "·" }
        span { @hint }
        span(class: TAG_CLASS) { @tag } if @tag
      end
      div(class: ROW_CLASS, data: { swatch_row: true }) do
        row_options.each { |hex| render_row_option(hex) }
        render_details
      end
    end
  end

  private

  def render_row_option(hex)
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: field_name, value: hex, checked: hex == selected, class: "peer sr-only", aria_label: option_label(hex))
      if hex.empty?
        span(class: NONE_CLASS) { NONE_LABEL }
      elsif Branding::Palette.swatches.include?(hex)
        span(class: SWATCH_CLASS, data: { swatch: hex })
      else
        span(class: "#{SWATCH_CLASS} #{FILLS.fetch(@attribute)}")
      end
    end
  end

  def render_details
    details(class: DETAILS_CLASS, open: custom?) do
      summary(class: SUMMARY_CLASS, aria_label: "#{@label}: mais cores") { CUSTOM_SUMMARY }
      div(class: GRID_CLASS, data: { swatch_grid: true }) { Branding::Palette.swatches.each { |hex| render_grid_swatch(hex) } }
      render_custom_panel
    end
  end

  def render_grid_swatch(hex)
    label(class: GRID_OPTION_CLASS) do
      input(type: "radio", name: field_name, value: hex, class: "peer sr-only", aria_label: hex)
      span(class: GRID_SWATCH_CLASS, data: { swatch: hex })
    end
  end

  def render_custom_panel
    div(class: CUSTOM_PANEL_CLASS, data: { custom: true }) do
      input(type: "color", value: resolved, class: PICKER_CLASS, aria_label: PICKER_LABEL,
        data: { color: true, action: "input->color-swatch#syncFromSwatch" })
      input(type: "text", name: custom_field_name, value: resolved, class: CONTROL, aria_label: CODE_LABEL,
        data: { code: true, action: "input->color-swatch#syncFromText" })
      label(class: CUSTOM_CHOICE_CLASS) do
        input(type: "radio", name: field_name, value: Branding::CUSTOM_COLOR_CHOICE, checked: false, class: CHECKBOX)
        plain CUSTOM_CHOICE_LABEL
      end
    end
  end

  def suggestions = Branding::Palette::SUGGESTIONS.fetch(@attribute)

  def row_options
    return suggestions if suggestions.include?(selected)

    [ selected ] + suggestions.first(ROW_SIZE - 1)
  end

  def option_label(hex) = hex.empty? ? NONE_LABEL : hex

  def field_name = "branding[#{@attribute}]"

  def custom_field_name = "branding[#{@attribute}_custom]"

  def normalized(value) = value.presence&.upcase

  def selected = normalized(@selected).to_s

  def resolved = normalized(@selected) || normalized(@fallback) || Branding::DEFAULT_BRAND_600

  def custom? = normalized(@selected).present? && !Branding::Palette.swatches.include?(normalized(@selected))
end
