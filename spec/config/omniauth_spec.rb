require "rails_helper"

RSpec.describe "OmniAuth initializer" do
  it "obtains the Google credentials through the production-guarded helper, never inline ENV" do
    initializer = Rails.root.join("config/initializers/omniauth.rb").read

    expect(initializer).to include("Zubio.google_oauth_credentials")
    expect(initializer).not_to match(/ENV\[.GOOGLE_CLIENT/)
  end
end
