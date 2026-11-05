class Components::ColorChip < Components::Base
  FILLS = {
    brand_600: "bg-brand-600 text-brand-600",
    brand_secondary_600: "bg-secondary-600 text-secondary-600",
    brand_background: "bg-(--theme-bg) text-(--theme-bg)"
  }.freeze
  SIZES = {
    small: "h-4 w-4 rounded",
    large: "h-7 w-7 rounded-lg shadow-[inset_0_0_0_1px_rgba(14,26,36,0.12)]"
  }.freeze

  def initialize(attribute:, size:, data: nil)
    @attribute = attribute
    @size = size
    @data = data
  end

  def view_template
    span(class: "flex-none #{SIZES.fetch(@size)} #{FILLS.fetch(@attribute)}", data: @data)
  end
end
