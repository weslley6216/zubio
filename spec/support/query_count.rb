module QueryCount
  IGNORED_QUERY_NAMES = %w[SCHEMA TRANSACTION].freeze

  def count_queries
    queries = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
      queries += 1 unless IGNORED_QUERY_NAMES.include?(payload[:name])
    end

    yield

    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end
end

RSpec.configure do |config|
  config.include QueryCount, type: :request
  config.include QueryCount, type: :model
end
