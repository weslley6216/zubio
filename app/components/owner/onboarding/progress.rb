class Components::Owner::Onboarding::Progress < Components::Base
  GROUPS = {
    "colors" => "Sua marca",
    "name" => "Sua marca",
    "logo" => "Sua marca",
    "services" => "Seu atendimento",
    "working_hours" => "Seu atendimento"
  }.freeze

  WRAPPER_CLASS = "mb-3 flex items-center justify-between".freeze
  GROUP_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  COUNTER_CLASS = "text-xs text-ink-muted".freeze

  def initialize(step:)
    @step = step
  end

  def view_template
    div(class: WRAPPER_CLASS) do
      span(class: GROUP_CLASS) { GROUPS.fetch(@step) }
      span(class: COUNTER_CLASS) { "#{position} de #{total}" }
    end
  end

  private

  def position = Tenant::ONBOARDING_QUESTIONS.index(@step) + 1

  def total = Tenant::ONBOARDING_QUESTIONS.size
end
