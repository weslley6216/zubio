Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], scope: "email profile", prompt: "select_account"
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = ->(env) { Client::Auth::OmniauthController.action(:failure).call(env) }
