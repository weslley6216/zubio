require "rails_helper"

RSpec.describe "Owner login screen", type: :system, js: true do
  it "reveals the password and flips the button label when the owner taps Mostrar" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")

    visit new_owner_session_url(host: "#{tenant.subdomain}.zubio.com.br")
    fill_in "Senha", with: "s3cr3t123"
    click_on "Mostrar"

    expect(find_field("Senha")[:type]).to eq("text")
    expect(page).to have_button("Ocultar")
  end

  %w[light dark].each do |scheme|
    it "fits the login screen in a 390px phone, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      emulate_phone
      emulate_color_scheme(scheme)

      visit new_owner_session_url(host: "#{tenant.subdomain}.zubio.com.br")

      expect(page).to have_content("Entrar no painel")
      expect(page).to have_content(tenant.name)
      expect(page).to fit_the_phone_width
    end
  end

  it "keeps the focus ring on the e-mail field and drops it inside the branded password box" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    visit new_owner_session_url(host: "#{tenant.subdomain}.zubio.com.br")

    find_field("E-mail").click
    email_outline = computed("input[type=email]", "outlineStyle")
    find_field("Senha").click

    expect(email_outline).to eq("solid")
    expect(computed("input[type=password]", "outlineStyle")).to eq("none")
  end
end
