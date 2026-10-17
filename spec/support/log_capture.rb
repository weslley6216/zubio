module LogCapture
  def capture_request_log
    buffer = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(buffer)
    yield
    buffer.string
  ensure
    Rails.logger = previous
  end
end

RSpec.configure { |config| config.include LogCapture, type: :request }
