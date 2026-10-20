OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.before(:each, type: :request) { OmniAuth.config.mock_auth[:google_oauth2] = nil }
  config.after(:each, type: :request) { OmniAuth.config.mock_auth[:google_oauth2] = nil }
  config.before(:each, type: :system) { OmniAuth.config.mock_auth[:google_oauth2] = nil }
  config.after(:each, type: :system) { OmniAuth.config.mock_auth[:google_oauth2] = nil }
end
