class Views::Layouts::Application < Views::Base
  include Phlex::Rails::Layout

  def initialize(title:, branding:)
    @title = title
    @branding = branding
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
      body(class: "min-h-dvh font-sans", &block)
    end
  end

  private

  # safe() is sound here because css_variables only concatenates values that
  # already passed Branding::ColorScale's allowlist — never raw user input.
  def css_variables
    ":root{#{@branding.css_variables}}"
  end
end
