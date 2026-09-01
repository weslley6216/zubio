class Views::Pages::Home < Views::Base
  def initialize(branding:, showcase_brands:)
    @branding = branding
    @showcase_brands = showcase_brands
  end

  def view_template
    render Views::Layouts::Application.new(title: "Zubio · Agendamento online com a sua marca", branding: @branding) do
      style { raw safe(Landing::ShowcaseBrand.css_rules) }
      div(class: "min-h-dvh bg-canvas font-sans text-ink", data: { landing_root: true }) do
        render Views::Pages::Home::SiteHeader.new
        render Views::Pages::Home::Hero.new(showcase_brands: @showcase_brands)
      end
    end
  end
end
