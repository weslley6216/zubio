require "capybara/rspec"
require "capybara/cuprite"

Capybara.javascript_driver = :cuprite

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    unless Rails.root.join("app/assets/builds/tailwind.css").exist?
      raise "app/assets/builds/tailwind.css is missing — run bin/rails tailwindcss:build"
    end

    driven_by :cuprite, screen_size: [ 1200, 800 ], options: {
      process_timeout: 60,
      browser_options: {
        "no-sandbox" => nil,
        "disable-gpu" => nil,
        "host-resolver-rules" => "MAP zubio.com.br 127.0.0.1, MAP *.zubio.com.br 127.0.0.1"
      }
    }
  end
end
