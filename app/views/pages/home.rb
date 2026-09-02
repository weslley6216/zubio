class Views::Pages::Home < Views::Base
  def initialize(branding:, showcase_brands:)
    @branding = branding
    @showcase_brands = showcase_brands
  end

  def view_template
    render layout do
      div(class: "min-h-dvh font-sans", data: { landing_root: true }) do
        render Views::Pages::Home::SiteHeader.new
        div(data: { controller: "showcase-brand" }) do
          render Views::Pages::Home::Hero.new do
            div(class: "grid justify-items-center gap-5") do
              render Views::Pages::Home::BookingPreview.new(showcase_brands: @showcase_brands)
              render Views::Pages::Home::ShowcasePicker.new(showcase_brands: @showcase_brands)
            end
          end
        end
        render Views::Pages::Home::HowItWorks.new
        render Views::Pages::Home::Features.new
        render Views::Pages::Home::DashboardPreview.new(showcase_brands: @showcase_brands)
        render Views::Pages::Home::Whitelabel.new(showcase_brands: @showcase_brands)
        render Views::Pages::Home::Faq.new
        render Views::Pages::Home::FinalCta.new
        render Views::Pages::Home::SiteFooter.new
      end
    end
  end

  private

  def layout
    Views::Layouts::Application.new(
      title: "Zubio · Agendamento online com a sua marca",
      branding: @branding,
      page_css: showcase_css,
      root_class: "bg-canvas text-ink [color-scheme:light_dark]"
    )
  end

  # safe() in the layout is sound for this string because every color in it comes
  # from the frozen showcase catalog through Branding::ColorScale, never from user input.
  def showcase_css = Landing::ShowcaseBrand.css_rules(@showcase_brands)
end
