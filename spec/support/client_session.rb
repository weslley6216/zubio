module ClientRequestSession
  def sign_in_client(client)
    host! "#{client.tenant.subdomain}.zubio.com.br"
    get client_handoff_path(token: client.handoff_token)
  end
end

RSpec.configure do |config|
  config.include ClientRequestSession, type: :request
end
