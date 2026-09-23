class Components::Form::ColorSwatches < Components::Base
  include Components::Form::Styles

  CUSTOM_SUMMARY = "+".freeze
  PICKER_LABEL = "Escolher a cor em um seletor".freeze
  CODE_LABEL = "Código hexadecimal da cor".freeze
  NONE_LABEL = "Sem".freeze
  ROW_SIZE = 5

  LEGEND_CLASS = "flex w-full items-baseline gap-1.5 text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  TAG_CLASS = "ml-auto normal-case".freeze
  GRID_CLASS = "mt-1.5 grid w-full grid-cols-6 gap-2".freeze
  ROW_OPTION_CLASS = "block".freeze
  SWATCH_CLASS = "block aspect-square rounded-xl ring-1 ring-line peer-checked:shadow-[0_0_0_3px_var(--color-canvas),0_0_0_5px_currentColor]".freeze
  NONE_CLASS = "flex aspect-square w-full items-center justify-center rounded-xl border border-line-strong bg-surface text-[10px] font-extrabold text-ink-muted peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:ring-offset-canvas peer-checked:ring-ink".freeze
  CUSTOM_CLASS = "grid aspect-square w-full place-items-center rounded-xl border border-dashed border-line-strong bg-surface".freeze
  CUSTOM_ICON_CLASS = "h-4.5 w-4.5 text-ink-muted".freeze
  PANEL_CLASS = "mt-2 hidden w-full items-end gap-2 group-has-[input[value='custom']:checked]:flex".freeze
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
      div(class: "group contents") do
        div(class: GRID_CLASS, data: { swatch_row: true }) do
          row_options.each { |hex| render_row_option(hex) }
          render_custom_option
        end
        render_custom_panel
      end
    end
  end

  private

  def render_row_option(hex)
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: field_name, value: hex, checked: !custom? && hex == selected, class: "peer sr-only", aria_label: option_label(hex))
      if hex.empty?
        span(class: NONE_CLASS) { NONE_LABEL }
      elsif Branding::Palette.swatches.include?(hex)
        span(class: SWATCH_CLASS, data: { swatch: hex })
      else
        render Components::ColorChip.new(attribute: @attribute, size: :row)
      end
    end
  end

  def render_custom_option
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: field_name, value: Branding::CUSTOM_COLOR_CHOICE, checked: custom?, class: "peer sr-only",
        aria_label: "#{@label}: #{CUSTOM_SUMMARY}")
      span(class: CUSTOM_CLASS) { render_custom_icon }
    end
  end

  def render_custom_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: CUSTOM_ICON_CLASS) do |icon|
      icon.path(d: "M12 5v14M5 12h14")
    end
  end

  def render_custom_panel
    div(class: PANEL_CLASS, data: { custom: true }) do
      input(type: "color", value: resolved, class: PICKER_CLASS, aria_label: PICKER_LABEL,
        data: { color: true, action: "input->color-swatch#syncFromSwatch" })
      input(type: "text", name: custom_field_name, value: resolved, class: CONTROL, aria_label: CODE_LABEL,
        data: { code: true, action: "input->color-swatch#syncFromText" })
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
