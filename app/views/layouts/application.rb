class Views::Layouts::Application < Views::Base
  include Phlex::Rails::Layout

  def initialize(title:, branding:, page_css: nil, root_class: nil)
    @title = title
    @branding = branding
    @page_css = page_css
    @root_class = root_class
  end

  def view_template(&block)
    doctype
    html(lang: "pt-BR", class: @root_class) do
      head { render_head }
      body(class: "min-h-dvh font-sans", &block)
    end
  end

  private

  def render_head
    meta(charset: "utf-8")
    meta(name: "viewport", content: "width=device-width, initial-scale=1")
    title { @title }
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
    javascript_importmap_tags
    style { raw safe(css_variables) }
    style { raw safe(@page_css) } if @page_css
  end

  # safe() is sound here because css_variables only concatenates values that
  # already passed Branding::ColorScale's allowlist — never raw user input.
  def css_variables
    ":root{#{@branding.css_variables}}"
  end
end
