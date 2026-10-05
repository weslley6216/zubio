class Components::Toggle < Components::Base
  TRACK_CLASS = "relative inline-flex h-[26px] w-[46px] flex-none cursor-pointer items-center rounded-full bg-line p-[3px] has-checked:bg-brand-600".freeze
  THUMB_CLASS = "h-5 w-5 rounded-full bg-white transition-transform peer-checked:translate-x-5".freeze

  def initialize(name: nil, value: "1", checked: false, id: nil, data: {})
    @name = name
    @value = value
    @checked = checked
    @id = id
    @data = data
  end

  def view_template
    label(class: TRACK_CLASS) do
      input(type: "checkbox", class: "peer sr-only", name: @name, value: @value, checked: @checked, id: @id, data: @data)
      span(class: THUMB_CLASS)
    end
  end
end
