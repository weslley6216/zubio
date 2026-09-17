class Views::Owner::Onboarding::Step < Views::Base
  include Components::Form::Styles

  TITLE = "Zubio".freeze
  SECONDARY_CLASS = "mt-2 h-11 w-full cursor-pointer text-sm font-medium text-ink-muted".freeze

  def initialize(branding:, body:, step:, submit_url:, submit_label:, secondary: nil, page_stylesheet: nil)
    @branding = branding
    @body = body
    @step = step
    @submit_url = submit_url
    @submit_label = submit_label
    @secondary = secondary
    @page_stylesheet = page_stylesheet
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: @branding, page_stylesheet: @page_stylesheet, view_transition: true) do
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        render Components::Owner::Onboarding::Progress.new(step: @step)
        section(class: Components::Owner::FormCard::CARD_CLASS) do
          form_with(url: @submit_url, method: :patch, multipart: true, class: Components::Owner::FormCard::FORM_CLASS, data: form_data) do |form|
            render @body
            render_nav(form)
          end
        end
      end
    end
  end

  private

  def form_data
    @step == "name" ? { turbo: false } : {}
  end

  def render_nav(form)
    form.submit @submit_label, class: SUBMIT
    form.submit @secondary, class: SECONDARY_CLASS if @secondary
  end
end
