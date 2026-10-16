class Views::Owner::BrandQuestions::Edit < Views::Base
  include Components::Form::Styles

  SUBMIT_LABEL = "Salvar".freeze

  def initialize(tenant:, branding:, current_section:, subtitle:, body:, url:, page_stylesheet:)
    @tenant = tenant
    @branding = branding
    @current_section = current_section
    @subtitle = subtitle
    @body = body
    @url = url
    @page_stylesheet = page_stylesheet
  end

  def view_template
    render Views::Layouts::Application.new(title: "Marca · #{@tenant.name}", branding: @branding, page_stylesheet: @page_stylesheet, flash_in_content: true) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render Components::FlashBanner.new(container_class: "mx-auto grid w-full max-w-[1040px] gap-2 px-5 pt-4")
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        render Components::Owner::SettingsBackLink.new
        section(aria_labelledby: @body::HEADING_ID, data: preview_data, class: Components::Owner::FormCard::CARD_CLASS) do
          form_with(url: @url, method: :patch, multipart: true, class: Components::Owner::FormCard::FORM_CLASS) do |form|
            render @body.new(tenant: @tenant, branding: @branding)
            form.submit(SUBMIT_LABEL, class: PLATFORM_SUBMIT)
          end
        end
      end
    end
  end

  private

  def preview_data
    { panel: true, preview_brand: @branding.brand_600, preview_secondary: @branding.brand_secondary_600.presence || "none" }
  end
end
