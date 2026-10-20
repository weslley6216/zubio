module LogCapture
  def capture_request_log
    buffer = StringIO.new
    previous = Rails.logger
    previous_controller = ActionController::Base.logger
    Rails.logger = ActiveSupport::Logger.new(buffer)
    ActionController::Base.logger = Rails.logger
    yield
    buffer.string
  ensure
    Rails.logger = previous
    ActionController::Base.logger = previous_controller
  end
end

RSpec.configure { |config| config.include LogCapture, type: :request }
