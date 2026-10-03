module PhlexComponent
  def render_phlex(component, &block)
    context = { rails_view_context: phlex_view_context, capture_context: phlex_view_context }
    component.call(context: context, &block)
  end

  private

  def phlex_view_context
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.view_context
  end
end

RSpec.configure do |config|
  config.include PhlexComponent, type: :component
end
