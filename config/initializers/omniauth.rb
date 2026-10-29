client_id, client_secret = Zubio.google_oauth_credentials

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, client_id, client_secret,
    scope: "email profile", prompt: "select_account", origin_param: "state"
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = ->(env) { Client::Auth::OmniauthController.action(:failure).call(env) }
