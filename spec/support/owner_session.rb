module OwnerSession
  def sign_in_owner(owner)
    visit "http://#{owner.tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: owner.password
    click_on "Entrar"
    page.has_no_button?("Entrar")
  end
end

RSpec.configure do |config|
  config.include OwnerSession, type: :system
end
