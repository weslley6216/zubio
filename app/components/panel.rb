class Components::Panel < Components::Base
  def initialize(title:)
    @title = title
  end

  def view_template
    div(class: "mx-auto mt-16 w-full max-w-sm rounded-xl border border-line bg-surface p-6") do
      h1(class: "mb-6 text-center text-2xl font-semibold text-ink") { @title }
      yield
    end
  end
end
