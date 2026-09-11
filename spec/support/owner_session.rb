module OwnerSession
  def sign_in_owner(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: owner.password
    click_on "Entrar"

    expect(page).to have_content(tenant.name)
  end
end

RSpec.configure do |config|
  config.include OwnerSession, type: :system
end
