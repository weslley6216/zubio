class Components::ContrastMark < Components::Base
  def view_template
    span(class: "relative block h-5 w-5 flex-none overflow-hidden rounded-full border-2 border-ink") do
      span(class: "absolute inset-y-0 left-0 w-1/2 bg-ink")
    end
  end
end
