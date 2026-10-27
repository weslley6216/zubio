class Components::Owner::Emblem < Components::Base
  SIZES = {
    small: "h-7 w-7 rounded-lg text-xs",
    medium: "h-8 w-8 rounded-lg",
    header: "h-9 w-9 rounded-[10px] text-[15px]",
    large: "h-12 w-12 rounded-[14px] text-[21px]",
    address: "h-11 w-11 rounded-[13px] text-[19px]",
    row: "h-6.5 w-6.5 rounded-lg text-xs",
    showcase: "h-14 w-14 rounded-[16px] text-[24px] leading-[normal]",
    login: "h-16 w-16 rounded-[18px] text-[28px] leading-[normal]",
    client: "h-10 w-10 rounded-[10px] text-base"
  }.freeze
  TONES = {
    accent: "bg-brand-accent text-on-brand-accent",
    translucent: "bg-on-brand/20 text-on-brand"
  }.freeze
  IMAGE_CLASS = "flex-none object-cover".freeze
  INITIAL_CLASS = "grid flex-none place-items-center font-extrabold".freeze

  def initialize(tenant:, branding:, size:, tone: :accent)
    @tenant = tenant
    @branding = branding
    @size = size
    @tone = tone
  end

  def view_template
    size_class = SIZES.fetch(@size)
    logo = @branding.header_logo

    if logo
      img(src: rails_storage_proxy_path(logo), alt: "", class: "#{size_class} #{IMAGE_CLASS}", data: { brand_logo: true })
    else
      span(class: "#{size_class} #{INITIAL_CLASS} #{TONES.fetch(@tone)}", data: { brand_initial: true }) { @tenant.initial }
    end
  end
end
