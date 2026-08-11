class Views::Layouts::Application < Views::Base
  include Phlex::Rails::Layout

  def initialize(title:)
    @title = title
  end

  def view_template(&block)
    doctype
    html(lang: "pt-BR") do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width, initial-scale=1")
        title { @title }
        csrf_meta_tags
        csp_meta_tag
        stylesheet_link_tag(:app, "data-turbo-track": "reload")
        javascript_importmap_tags
        style { raw safe(css_variables) }
      end
      body(class: "min-h-dvh bg-background text-foreground font-sans", &block)
    end
  end

  private

  def branding
    @branding ||= ActsAsTenant.current_tenant.branding || Branding.platform_default
  end

  # safe() aqui é seguro porque css_variables só concatena valores que já
  # passaram pela allowlist de Branding::ColorScale — nunca texto cru de input.
  def css_variables
    ":root{#{branding.css_variables}}"
  end
end
