require "rails_helper"

RSpec.describe "Owner brand colors", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, email: "ze@example.com", password: "s3cr3t123") }

  def sign_in(establishment = tenant, user = owner)
    host! "#{establishment.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: user.email, password: "s3cr3t123" }
  end

  describe "GET /owner/brand_colors/edit" do
    it "renders the colors question with the palette sheet, marking settings as the current section" do
      create(:branding, tenant: tenant, brand_600: "#2C6CB0")
      sign_in

      get edit_owner_brand_colors_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Components::Owner::BrandQuestion::Colors::TITLE)
      expect(response.body).to include(palette_stylesheet_path(v: Branding::Palette.stylesheet_digest))
      expect(response.body).to include(%(<a href="#{owner_settings_path}" aria-current="page"))
    end

    it "reaches the whole grid and the code field through the plus, without JavaScript" do
      create(:branding, tenant: tenant, brand_600: "#2C6CB0")
      sign_in

      get edit_owner_brand_colors_path

      Branding::Palette.swatches.each { |hex| expect(response.body).to include(%(data-swatch="#{hex}")) }
      expect(response.body).to include(%(name="branding[brand_600_custom]"))
    end

    it "sends an anonymous visitor to the login" do
      host! "#{tenant.subdomain}.zubio.com.br"

      get edit_owner_brand_colors_path

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "PATCH /owner/brand_colors" do
    it "changes only the brand color, leaving the name and the logo untouched" do
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      sign_in

      patch owner_brand_colors_path, params: { branding: { brand_600: "#2F6FED" } }

      expect(response).to redirect_to(edit_owner_brand_colors_path)
      ActsAsTenant.with_tenant(tenant) do
        expect(tenant.reload.name).to eq("Barbearia do Zé")
        expect(tenant.branding.brand_600).to eq("#2F6FED")
        expect(tenant.branding.logo).to be_attached
      end
    end

    it "stores a swatch chosen from the grid without any typed code" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      sign_in

      patch owner_brand_colors_path, params: { branding: { brand_600: Branding::Palette.swatches.last, brand_600_custom: "" } }

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq(Branding::Palette.swatches.last) }
    end

    it "clears the support color and keeps the establishment valid when the owner chooses none" do
      create(:branding, :with_secondary, tenant: tenant, brand_600: "#4F46E5")
      sign_in

      patch owner_brand_colors_path, params: { branding: { brand_600: "#4F46E5", brand_secondary_600: "" } }

      expect(response).to redirect_to(edit_owner_brand_colors_path)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_secondary_600).to be_nil }
    end

    it "refuses a color without contrast on the same screen and keeps the stored one" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      sign_in

      patch owner_brand_colors_path, params: { branding: { brand_600: "#7A7A7A" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(Owner::BrandQuestionsController::REFUSED)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#4F46E5") }
    end

    it "does not touch another establishment's brand and shows nothing of it" do
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: other_tenant, brand_600: "#000000")
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      sign_in

      patch owner_brand_colors_path, params: { branding: { brand_600: "#2F6FED" } }

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#2F6FED") }
      expect(other_tenant.reload.name).to eq("Estúdio Aurora")
      ActsAsTenant.with_tenant(other_tenant) { expect(other_tenant.branding.reload.brand_600).to eq("#000000") }

      get edit_owner_brand_colors_path
      expect(response.body).not_to include("Estúdio Aurora")
      expect(response.body).not_to include("#000000")
    end
  end

  describe "the retired single brand screen" do
    it "answers not found" do
      sign_in

      get "/owner/branding/edit"

      expect(response).to have_http_status(:not_found)
    end
  end
end
