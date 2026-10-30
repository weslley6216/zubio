RSpec.configure do |config|
  config.around(:each, :cable) do |example|
    cable = ActionCable.server.config.cable
    queue = ActiveJob::Base.queue_adapter
    ActionCable.server.config.cable = { "adapter" => "async" }
    ActionCable.server.instance_variable_set(:@pubsub, nil)
    ActiveJob::Base.queue_adapter = :inline
    example.run
  ensure
    ActiveJob::Base.queue_adapter = queue
    ActionCable.server.config.cable = cable
    ActionCable.server.instance_variable_set(:@pubsub, nil)
  end
end
