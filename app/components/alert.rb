class Components::Alert < Components::Base
  def initialize(text:)
    @text = text
  end

  def view_template
    p(class: "mb-4 rounded-md bg-danger-surface px-4 py-2 text-sm text-danger") { @text }
  end
end
