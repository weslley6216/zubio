require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

require_relative "support/capybara"
require_relative "support/client_session"
require_relative "support/computed_style"
require_relative "support/legible_roles"
require_relative "support/live_updates"
require_relative "support/log_capture"
require_relative "support/neutral_mirror"
require_relative "support/omniauth"
require_relative "support/owner_session"
require_relative "support/phlex_component"
require_relative "support/phone"
require_relative "support/probe_controllers"
require_relative "support/pwa_environment"
require_relative "support/query_count"
require_relative "support/skeleton_probe"
require_relative "support/submit_lock_probe"
require_relative "support/waiting"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  config.before(:each) { Rails.cache.clear }
  config.include ActiveJob::TestHelper, type: :request
  config.include ActiveJob::TestHelper, type: :model
  config.include ActiveJob::TestHelper, type: :mailer
  config.include ActiveSupport::Testing::TimeHelpers
  config.include Turbo::Broadcastable::TestHelper, type: :model
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
