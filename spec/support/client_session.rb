module ClientRequestSession
  def sign_in_client(client)
    host! "#{client.tenant.subdomain}.zubio.com.br"
    get client_handoff_path(token: client.handoff_token)
  end
end

module ClientSystemSession
  def sign_in_client(client)
    visit "http://#{client.tenant.subdomain}.zubio.com.br#{client_handoff_path(token: client.handoff_token)}"
  end
end

RSpec.configure do |config|
  config.include ClientRequestSession, type: :request
  config.include ClientSystemSession, type: :system
end
