class Components::ColorChip < Components::Base
  FILLS = { brand_600: "bg-brand-600", brand_secondary_600: "bg-secondary-600" }.freeze
  SIZES = { small: "h-4 w-4 rounded", large: "h-5.5 w-5.5 rounded-md" }.freeze

  def initialize(attribute:, size:, data: nil)
    @attribute = attribute
    @size = size
    @data = data
  end

  def view_template
    span(class: "flex-none #{SIZES.fetch(@size)} #{FILLS.fetch(@attribute)}", data: @data)
  end
end
