class Views::Owner::BrandQuestions::Edit < Views::Base
  include Components::Form::Styles

  BACK_LABEL = "Configurações".freeze
  SUBMIT_LABEL = "Salvar".freeze
  BACK_CLASS = "inline-flex min-h-11 items-center gap-1 text-sm font-bold text-ink-muted hover:text-ink".freeze
  BACK_ICON = "m15 6-6 6 6 6".freeze

  def initialize(tenant:, branding:, current_section:, body:, back_to:, url:, page_stylesheet:)
    @tenant = tenant
    @branding = branding
    @current_section = current_section
    @body = body
    @back_to = back_to
    @url = url
    @page_stylesheet = page_stylesheet
  end

  def view_template
    render Views::Layouts::Application.new(title: "Marca · #{@tenant.name}", branding: @branding, page_stylesheet: @page_stylesheet) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        render_back
        section(aria_label: BACK_LABEL, data: { panel: true }, class: Components::Owner::FormCard::CARD_CLASS) do
          form_with(url: @url, method: :patch, multipart: true, class: Components::Owner::FormCard::FORM_CLASS) do |form|
            render @body.new(tenant: @tenant, branding: @branding)
            form.submit(SUBMIT_LABEL, class: SUBMIT)
          end
        end
      end
    end
  end

  private

  def render_back
    a(href: @back_to, class: BACK_CLASS) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-4 w-4") { |icon| icon.path(d: BACK_ICON) }
      plain BACK_LABEL
    end
  end
end
