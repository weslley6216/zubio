class Views::Layouts::Application < Views::Base
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::ContentSecurityPolicyNonce

  THEME_BOOTSTRAP = <<~JS.freeze
    try {
      var theme = localStorage.getItem("theme");
      if (theme === "dark" || theme === "light") document.documentElement.dataset.theme = theme;
    } catch (error) {}
  JS

  SURFACE_CLASS = "bg-canvas text-ink [color-scheme:light_dark]".freeze
  FLASH_CLASS = "mx-auto grid w-full max-w-6xl gap-2 px-6 pt-4".freeze
  BODY_CLASS = "min-h-dvh font-sans [&:has([data-owner-menu][open])>:not(header)]:opacity-45".freeze

  def initialize(title:, branding:, page_stylesheet: nil, view_transition: false, social: nil, flash_in_content: false)
    @title = title
    @branding = branding
    @page_stylesheet = page_stylesheet
    @view_transition = view_transition
    @social = social
    @flash_in_content = flash_in_content
  end

  def view_template(&block)
    doctype
    html(lang: "pt-BR", class: SURFACE_CLASS) do
      head { render_head }
      body(class: BODY_CLASS) do
        render Components::FlashBanner.new(container_class: FLASH_CLASS) unless @flash_in_content
        yield if block
      end
    end
  end

  private

  def render_head
    meta(charset: "utf-8")
    meta(name: "viewport", content: "width=device-width, initial-scale=1")
    meta(name: "view-transition", content: "same-origin") if @view_transition
    render_theme_bootstrap
    title { @title }
    render @social if @social
    csrf_meta_tags
    csp_meta_tag
    meta(name: "theme-color", content: @branding.brand_600)
    meta(name: "apple-mobile-web-app-capable", content: "yes")
    meta(name: "mobile-web-app-capable", content: "yes")
    link(rel: "icon", href: "/icon.png", type: "image/png")
    link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
    link(rel: "apple-touch-icon", href: "/icon.png")
    link(rel: "manifest", href: pwa_manifest_path)
    stylesheet_link_tag(:app, "data-turbo-track": "reload")
    link(rel: "stylesheet", href: branding_stylesheet_path(v: @branding.stylesheet_digest), data: { turbo_track: "dynamic" })
    link(rel: "stylesheet", href: @page_stylesheet, data: { turbo_track: "dynamic" }) if @page_stylesheet
    javascript_importmap_tags
  end

  def render_theme_bootstrap
    script(nonce: content_security_policy_nonce) { raw safe(THEME_BOOTSTRAP) }
  end
end
