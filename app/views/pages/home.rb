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
        div(data: { controller: "showcase-brand" }) do
          render Views::Pages::Home::Hero.new(showcase_brands: @showcase_brands) do
            div(class: "grid justify-items-center gap-5") do
              render Views::Pages::Home::BookingPreview.new(showcase_brands: @showcase_brands)
              render Views::Pages::Home::ShowcasePicker.new(showcase_brands: @showcase_brands)
            end
          end
        end
        render Views::Pages::Home::HowItWorks.new
        render Views::Pages::Home::Features.new
      end
    end
  end
end
