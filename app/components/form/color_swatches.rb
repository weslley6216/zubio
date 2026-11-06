class Components::Form::ColorSwatches < Components::Base
  include Components::Form::Styles

  PICKER_LABEL = "Escolher a cor em um seletor".freeze
  CODE_LABEL = "Código hexadecimal da cor".freeze
  CUSTOM_SUMMARY = "+".freeze
  MORE_LABEL = "Mais cores".freeze
  CUSTOMIZE_LABEL = "Personalizar".freeze
  INVALID_HEX_MESSAGE = "não é uma cor válida".freeze

  FIELDSET_CLASS = "flex min-w-0 flex-col gap-2.5".freeze
  LEGEND_CLASS = "mb-2.5 flex w-full flex-col gap-0.5".freeze
  LABEL_CLASS = "text-[14px] font-extrabold text-ink".freeze
  HINT_CLASS = "text-[12px] text-ink-muted".freeze
  ROW_CLASS = "flex flex-wrap gap-2.5".freeze
  ROW_OPTION_CLASS = "block".freeze
  CUSTOM_CLASS = "grid h-11 w-11 place-items-center rounded-xl border-[1.5px] border-dashed border-ink-subtle text-[20px] font-bold text-ink-muted".freeze
  CUSTOMIZE_OPTION_CLASS = "block".freeze
  CUSTOMIZE_CLASS = "flex h-11 items-center justify-center gap-1.5 rounded-xl border border-dashed border-line-strong bg-surface px-2 text-xs font-bold text-ink-muted peer-checked:border-solid peer-checked:text-ink peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:ring-offset-canvas peer-checked:ring-ink".freeze
  PICKER_CLASS = "h-11 w-11 flex-none cursor-pointer rounded-lg border border-line".freeze
  DISCLOSURE_CLASS = "hidden group-has-[[data-more-toggle]:checked]:block group-has-[input[value='custom']:checked]:block".freeze
  PANEL_CLASS = "mt-2 hidden w-full items-end gap-2 group-has-[input[value='custom']:checked]:flex".freeze
  ERROR_CLASS = "mt-1 text-sm text-danger".freeze

  def initialize(label:, hint:, attribute:, selected:, fallback: Branding::DEFAULT_BRAND_600)
    @label = label
    @hint = hint
    @attribute = attribute
    @selected = selected
    @fallback = fallback
  end

  def view_template
    fieldset(aria_label: @label, class: FIELDSET_CLASS) do
      legend(class: LEGEND_CLASS) do
        span(class: LABEL_CLASS) { @label }
        span(class: HINT_CLASS) { @hint }
      end
      div(class: "group contents") do
        div(class: ROW_CLASS, data: { swatch_row: true }) do
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
      input(type: "radio", name: field_name, value: hex, checked: !custom? && hex == selected, class: "peer sr-only", aria_label: hex)
      span(class: SWATCH_CLASS, data: { swatch: hex })
    end
  end

  def render_more_toggle
    label(class: ROW_OPTION_CLASS, data: { row_option: true }) do
      input(type: "checkbox", checked: custom?, class: "peer sr-only", aria_label: "#{MORE_LABEL} (#{CUSTOM_SUMMARY})",
        data: { more_toggle: true })
      span(class: CUSTOM_CLASS) { CUSTOM_SUMMARY }
    end
  end

  def render_disclosure
    div(class: DISCLOSURE_CLASS) do
      render_customize_option
      render_custom_panel
    end
  end

  def render_customize_option
    label(class: CUSTOMIZE_OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: field_name, value: Branding::CUSTOM_COLOR_CHOICE, checked: custom?, class: "peer sr-only",
        aria_label: "#{@label}: #{CUSTOMIZE_LABEL}")
      span(class: CUSTOMIZE_CLASS) do
        render Components::ColorChip.new(attribute: @attribute, size: :small) if custom?
        span { CUSTOMIZE_LABEL }
      end
    end
  end

  def render_custom_panel
    div(class: PANEL_CLASS, data: { custom: true }) do
      input(type: "color", value: resolved, class: PICKER_CLASS, aria_label: PICKER_LABEL,
        data: { color: true, action: "input->color-swatch#syncFromSwatch" })
      div(class: "flex-1") do
        input(type: "text", name: custom_field_name, value: resolved, class: CONTROL, aria_label: CODE_LABEL,
          data: { code: true, action: "input->color-swatch#syncFromText" })
        p(id: error_id, class: ERROR_CLASS, hidden: true, role: "alert", data: { color_error: true }) { INVALID_HEX_MESSAGE }
      end
    end
  end

  def error_id = "#{@attribute}-color-error"

  def suggestions = Branding::Palette::SUGGESTIONS.fetch(@attribute)

  def field_name = "branding[#{@attribute}]"

  def custom_field_name = "branding[#{@attribute}_custom]"

  def normalized(value) = value.presence&.upcase

  def selected = normalized(@selected).to_s

  def resolved = normalized(@selected) || normalized(@fallback) || Branding::DEFAULT_BRAND_600

  def custom? = normalized(@selected).present? && !Branding::Palette.swatches.include?(normalized(@selected))
end
