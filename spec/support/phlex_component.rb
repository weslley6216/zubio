module PhlexComponent
  def render_phlex(component, flash: {}, &block)
    view_context = phlex_view_context(flash)
    context = { rails_view_context: view_context, capture_context: view_context }
    component.call(context: context, &block)
  end

  private

  def phlex_view_context(flash)
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    flash.each { |key, message| controller.request.flash[key] = message }
    controller.view_context
  end
end

RSpec.configure do |config|
  config.include PhlexComponent, type: :component
end
