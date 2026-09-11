RSpec.configure do |config|
  config.before(:each) { Rails.cache.clear }
end
