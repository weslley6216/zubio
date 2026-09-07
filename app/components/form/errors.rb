class Components::Form::Errors < Components::Base
  def initialize(messages:)
    @messages = messages
  end

  def view_template
    return if @messages.empty?

    p(class: "mt-1 text-sm text-danger") { @messages.join(", ") }
  end
end
