class Components::Form::ColorSwatches < Components::Base
  include Components::Form::Styles

  CUSTOM_SUMMARY = "Personalizar".freeze
  CUSTOM_CHOICE_LABEL = "Usar este código".freeze
  PICKER_LABEL = "Escolher a cor em um seletor".freeze
  CODE_LABEL = "Código hexadecimal da cor".freeze
  GRID_CLASS = "mt-2 grid grid-cols-4 gap-2 sm:grid-cols-6".freeze
  SWATCH_CLASS = "block h-11 w-11 rounded-lg border-2 border-line peer-checked:border-ink peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-brand-accent".freeze
  SUMMARY_CLASS = "mt-3 inline-flex min-h-11 cursor-pointer list-none items-center text-sm font-medium text-ink underline [&::-webkit-details-marker]:hidden".freeze
  PICKER_CLASS = "h-11 w-11 flex-none cursor-pointer rounded-lg border border-line".freeze
  BLANK_CLASS = "mt-2 inline-flex min-h-11 items-center gap-2 text-sm text-ink".freeze

  def initialize(label:, name:, custom_name:, selected:, blank_label: nil)
    @label = label
    @name = name
    @custom_name = custom_name
    @selected = selected
    @blank_label = blank_label
  end

  def view_template
    fieldset(data: { controller: "color-swatch" }) do
      legend(class: LABEL) { @label }
      render_blank_choice if @blank_label
      div(class: GRID_CLASS) { Branding::Palette.swatches.each { |hex| render_swatch(hex) } }
      render_custom_disclosure
    end
  end

  private

  def render_blank_choice
    label(class: BLANK_CLASS) do
      input(type: "radio", name: @name, value: "", checked: @selected.blank?, class: CHECKBOX)
      plain @blank_label
    end
  end

  def render_swatch(hex)
    label(class: "block") do
      input(type: "radio", name: @name, value: hex, checked: @selected == hex, class: "peer sr-only", aria_label: hex)
      span(class: SWATCH_CLASS, data: { swatch: hex })
    end
  end

  def render_custom_disclosure
    details(open: custom?) do
      summary(class: SUMMARY_CLASS) { CUSTOM_SUMMARY }
      div(class: "mt-2 flex items-center gap-2") do
        render_custom_choice
        render_picker
        render_code_field
      end
    end
  end

  def render_custom_choice
    label(class: "inline-flex min-h-11 flex-none items-center gap-2 text-sm text-ink") do
      input(type: "radio", name: @name, value: Branding::CUSTOM_COLOR_CHOICE, checked: custom?,
        class: CHECKBOX, data: { "color-swatch-target": "custom" })
      plain CUSTOM_CHOICE_LABEL
    end
  end

  def render_picker
    input(type: "color", value: custom_value, class: PICKER_CLASS, aria_label: PICKER_LABEL,
      data: { "color-swatch-target": "swatch", action: "input->color-swatch#syncFromSwatch" })
  end

  def render_code_field
    input(type: "text", name: @custom_name, value: custom_value, class: CONTROL, aria_label: CODE_LABEL,
      data: { "color-swatch-target": "text", action: "input->color-swatch#syncFromText" })
  end

  def custom? = @selected.present? && !Branding::Palette.swatches.include?(@selected)

  def custom_value = custom? ? @selected : Branding::DEFAULT_BRAND_600
end
