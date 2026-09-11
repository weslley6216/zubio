class Components::Form::ColorSwatches < Components::Base
  include Components::Form::Styles

  CUSTOM_SUMMARY = "Outra".freeze
  CUSTOM_CHOICE_LABEL = "Usar este código".freeze
  PICKER_LABEL = "Escolher a cor em um seletor".freeze
  CODE_LABEL = "Código hexadecimal da cor".freeze
  OWN_LABEL = "Escolher outra".freeze
  CHIP_CLASSES = { brand_600: "bg-brand-600", brand_secondary_600: "bg-secondary-600" }.freeze

  LEGEND_CLASS = "w-full".freeze
  ROW_CLASS = "flex w-full items-center justify-between gap-2".freeze
  READOUT_CLASS = "flex items-center gap-2".freeze
  CHIP_CLASS = "h-4 w-4 flex-none rounded".freeze
  CODE_CLASS = "text-sm font-bold tabular-nums text-ink".freeze
  SUMMARY_CLASS = "cursor-pointer text-sm font-medium text-ink underline underline-offset-2".freeze
  SEGMENT_GROUP_CLASS = "mt-1.5 grid grid-cols-2 gap-1 rounded-xl bg-surface-3 p-1".freeze
  SEGMENT_CLASS = "inline-flex h-11 w-full cursor-pointer items-center justify-center rounded-lg px-3 text-sm font-bold text-ink-muted".freeze
  SEGMENT_CHECKED_CLASS = "peer-checked:bg-surface peer-checked:text-ink peer-checked:shadow-sm".freeze
  SEGMENT_EXPANDED_CLASS = "aria-expanded:bg-surface aria-expanded:text-ink aria-expanded:shadow-sm".freeze
  GRID_CLASS = "mt-2 grid grid-cols-8 gap-2".freeze
  SWATCH_CLASS = "block aspect-square rounded-lg ring-1 ring-line peer-checked:ring-2 peer-checked:ring-ink peer-checked:ring-offset-2 peer-checked:ring-offset-surface".freeze
  CUSTOM_PANEL_CLASS = "mt-2 flex items-end gap-2".freeze
  CUSTOM_CHOICE_CLASS = "inline-flex min-h-11 flex-none items-center gap-2 text-sm text-ink".freeze
  PICKER_CLASS = "h-11 w-11 flex-none cursor-pointer rounded-lg border border-line".freeze

  def initialize(label:, attribute:, selected:, fallback: Branding::DEFAULT_BRAND_600, linked_label: nil)
    @label = label
    @attribute = attribute
    @selected = selected
    @fallback = fallback
    @linked_label = linked_label
  end

  def view_template
    fieldset(aria_label: @label, data: { controller: "color-swatch", action: "change->color-swatch#showChoice" }) do
      legend(class: LEGEND_CLASS) { render_row }
      render_link_choice if @linked_label
      render_panel
    end
  end

  private

  def render_row
    span(class: ROW_CLASS) do
      span(class: LABEL) { @label }
      render_readout
    end
  end

  def render_readout
    span(class: READOUT_CLASS, hidden: linked?, data: { "color-swatch-target": "readout" }) do
      span(class: "#{CHIP_CLASS} #{CHIP_CLASSES.fetch(@attribute)}", data: { "color-swatch-target": "chip" })
      span(class: CODE_CLASS, data: { "color-swatch-target": "code" }) { resolved }
      button(type: "button", class: SUMMARY_CLASS, aria_expanded: custom?.to_s, aria_controls: code_panel_id,
        data: { "color-swatch-target": "customToggle", action: "color-swatch#toggleCustom" }) { CUSTOM_SUMMARY }
    end
  end

  def render_link_choice
    div(class: SEGMENT_GROUP_CLASS) do
      label do
        input(type: "radio", name: name, value: "", checked: linked?, class: "peer sr-only",
          data: { "color-swatch-target": "linked", action: "change->color-swatch#chooseLinked" })
        span(class: "#{SEGMENT_CLASS} #{SEGMENT_CHECKED_CLASS}") { @linked_label }
      end
      button(type: "button", class: "#{SEGMENT_CLASS} #{SEGMENT_EXPANDED_CLASS}", aria_expanded: (!linked?).to_s,
        aria_controls: palette_id, data: { "color-swatch-target": "own", action: "color-swatch#chooseOwn" }) { OWN_LABEL }
    end
  end

  def render_panel
    div(id: palette_id, hidden: linked?, data: { "color-swatch-target": "panel" }) do
      div(class: GRID_CLASS) { Branding::Palette.swatches.each { |hex| render_swatch(hex) } }
      render_custom_panel
    end
  end

  def render_swatch(hex)
    label(class: "block") do
      input(type: "radio", name: name, value: hex, checked: selected == hex, class: "peer sr-only", aria_label: hex)
      span(class: SWATCH_CLASS, data: { swatch: hex })
    end
  end

  def render_custom_panel
    div(id: code_panel_id, class: CUSTOM_PANEL_CLASS, hidden: !custom?, data: { "color-swatch-target": "customPanel" }) do
      render_picker
      render_code_field
      render_custom_choice
    end
  end

  def render_custom_choice
    label(class: CUSTOM_CHOICE_CLASS) do
      input(type: "radio", name: name, value: Branding::CUSTOM_COLOR_CHOICE, checked: custom?,
        class: CHECKBOX, data: { "color-swatch-target": "custom" })
      plain CUSTOM_CHOICE_LABEL
    end
  end

  def render_picker
    input(type: "color", value: resolved, class: PICKER_CLASS, aria_label: PICKER_LABEL,
      data: { "color-swatch-target": "swatch", action: "input->color-swatch#syncFromSwatch" })
  end

  def render_code_field
    input(type: "text", name: custom_name, value: resolved, class: CONTROL, aria_label: CODE_LABEL,
      data: { "color-swatch-target": "text", action: "input->color-swatch#syncFromText" })
  end

  def name = "branding[#{@attribute}]"

  def custom_name = "branding[#{@attribute}_custom]"

  def palette_id = "#{@attribute}-palette"

  def code_panel_id = "#{@attribute}-code"

  def normalized(value) = value.presence&.upcase

  def selected = normalized(@selected)

  def resolved = selected || normalized(@fallback) || Branding::DEFAULT_BRAND_600

  def linked? = @linked_label.present? && selected.blank?

  def custom? = selected.present? && !Branding::Palette.swatches.include?(selected)
end
