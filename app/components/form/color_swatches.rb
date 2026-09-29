class Components::Form::ColorSwatches < Components::Base
  include Components::Form::Styles

  PICKER_LABEL = "Escolher a cor em um seletor".freeze
  CODE_LABEL = "Código hexadecimal da cor".freeze
  NONE_LABEL = "Sem".freeze
  CUSTOM_SUMMARY = "+".freeze
  MORE_LABEL = "Mais cores".freeze
  CUSTOMIZE_LABEL = "Personalizar".freeze
  INVALID_HEX_MESSAGE = "não é uma cor válida".freeze

  LEGEND_CLASS = "flex w-full items-baseline gap-1.5 text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  TAG_CLASS = "ml-auto normal-case".freeze
  GRID_CLASS = "mt-1.5 grid w-full grid-cols-6 gap-2".freeze
  ROW_OPTION_CLASS = "block".freeze
  SWATCH_CLASS = "block aspect-square rounded-xl ring-1 ring-line peer-checked:shadow-[0_0_0_3px_var(--color-canvas),0_0_0_5px_currentColor]".freeze
  NONE_CLASS = "flex aspect-square w-full items-center justify-center rounded-xl border border-line-strong bg-surface text-[10px] font-extrabold text-ink-muted peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:ring-offset-canvas peer-checked:ring-ink".freeze
  CUSTOM_CLASS = "grid aspect-square w-full place-items-center rounded-xl border border-dashed border-line-strong bg-surface".freeze
  CUSTOM_ICON_CLASS = "h-4.5 w-4.5 text-ink-muted".freeze
  PICKER_CLASS = "h-11 w-11 flex-none cursor-pointer rounded-lg border border-line".freeze
  DISCLOSURE_CLASS = "hidden group-has-[[data-more-toggle]:checked]:block group-has-[input[value='custom']:checked]:block".freeze
  DISCLOSURE_GRID_CLASS = "mt-2 grid w-full grid-cols-6 gap-2".freeze
  PANEL_CLASS = "mt-2 hidden w-full items-end gap-2 group-has-[input[value='custom']:checked]:flex".freeze
  ERROR_CLASS = "mt-1 text-sm text-danger".freeze

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
          suggestions.each { |hex| render_row_option(hex) }
          render_more_toggle
        end
        render_disclosure
      end
    end
  end

  private

  def render_row_option(hex)
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: field_name, value: hex, checked: !custom? && hex == selected, class: "peer sr-only", aria_label: option_label(hex))
      if hex.empty?
        span(class: NONE_CLASS) { NONE_LABEL }
      else
        span(class: SWATCH_CLASS, data: { swatch: hex })
      end
    end
  end

  def render_more_toggle
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "checkbox", checked: !suggestion?, class: "peer sr-only", aria_label: "#{MORE_LABEL} (#{CUSTOM_SUMMARY})",
        data: { more_toggle: true })
      span(class: CUSTOM_CLASS) { render_custom_icon }
    end
  end

  def render_disclosure
    div(class: DISCLOSURE_CLASS) do
      div(class: DISCLOSURE_GRID_CLASS) do
        extras.each { |hex| render_row_option(hex) }
        render_customize_option
      end
      render_custom_panel
    end
  end

  def render_customize_option
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: field_name, value: Branding::CUSTOM_COLOR_CHOICE, checked: custom?, class: "peer sr-only",
        aria_label: "#{@label}: #{CUSTOMIZE_LABEL}")
      if custom?
        render Components::ColorChip.new(attribute: @attribute, size: :row)
      else
        span(class: CUSTOM_CLASS) { CUSTOMIZE_LABEL }
      end
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
      div(class: "flex-1") do
        input(type: "text", name: custom_field_name, value: resolved, class: CONTROL, aria_label: CODE_LABEL,
          aria_describedby: error_id, data: { code: true, action: "input->color-swatch#syncFromText" })
        p(id: error_id, class: ERROR_CLASS, hidden: true, role: "alert", data: { color_error: true }) { INVALID_HEX_MESSAGE }
      end
    end
  end

  def error_id = "#{@attribute}-color-error"

  def suggestions = Branding::Palette::SUGGESTIONS.fetch(@attribute)

  def extras = Branding::Palette.extras(@attribute)

  def suggestion? = suggestions.include?(selected)

  def option_label(hex) = hex.empty? ? NONE_LABEL : hex

  def field_name = "branding[#{@attribute}]"

  def custom_field_name = "branding[#{@attribute}_custom]"

  def normalized(value) = value.presence&.upcase

  def selected = normalized(@selected).to_s

  def resolved = normalized(@selected) || normalized(@fallback) || Branding::DEFAULT_BRAND_600

  def custom? = normalized(@selected).present? && !Branding::Palette.swatches.include?(normalized(@selected))
end
