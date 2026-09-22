class Components::Platform::Emblem < Components::Base
  BASE_CLASS = "grid place-items-center bg-brand-accent font-extrabold text-on-brand-accent".freeze

  SIZES = {
    header: "h-8 w-8 rounded-lg",
    onboarding: "h-13 w-13 rounded-2xl text-2xl"
  }.freeze

  def initialize(size:)
    @size = size
  end

  def view_template
    span(class: "#{BASE_CLASS} #{SIZES.fetch(@size)}") { "z" }
  end
end
