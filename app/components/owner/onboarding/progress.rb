class Components::Owner::Onboarding::Progress < Components::Base
  WRAPPER_CLASS = "mb-3 flex items-center justify-between".freeze
  GROUP_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  COUNTER_CLASS = "text-xs text-ink-muted".freeze

  def view_template
    div(class: WRAPPER_CLASS, data: { onboarding_target: "progress" }) do
      span(class: GROUP_CLASS, data: { onboarding_target: "group" })
      span(class: COUNTER_CLASS, data: { onboarding_target: "counter" })
    end
  end
end
