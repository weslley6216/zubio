Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self
    policy.style_src_attr :none
    policy.frame_ancestors :none
    policy.form_action :self, "*.#{Zubio::PLATFORM_HOST}:*"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
