class Components::Owner::Emblem < Components::Base
  SIZES = {
    small: "h-7 w-7 rounded-lg text-xs",
    medium: "h-8 w-8 rounded-lg",
    large: "h-12 w-12 rounded-xl"
  }.freeze
  IMAGE_CLASS = "flex-none object-contain".freeze
  INITIAL_CLASS = "grid flex-none place-items-center bg-brand-accent font-extrabold text-on-brand-accent".freeze

  def initialize(tenant:, branding:, size:)
    @tenant = tenant
    @branding = branding
    @size = size
  end

  def view_template
    size_class = SIZES.fetch(@size)
    logo = @branding.header_logo

    if logo
      img(src: rails_storage_proxy_path(logo), alt: "", class: "#{size_class} #{IMAGE_CLASS}")
    else
      span(class: "#{size_class} #{INITIAL_CLASS}") { @tenant.initial }
    end
  end
end
