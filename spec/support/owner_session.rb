module OwnerSession
  def sign_in_owner(owner)
    visit "http://#{owner.tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: owner.password
    click_on "Entrar"
    page.has_no_button?("Entrar") or raise "owner #{owner.email} did not get past the login form"
  end
end

module OwnerRequestSession
  def sign_in_owner(owner)
    host! "#{owner.tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: owner.password }
  end
end

RSpec.configure do |config|
  config.include OwnerSession, type: :system
  config.include OwnerRequestSession, type: :request
end
