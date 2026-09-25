require "rails_helper"

RSpec.describe "Owner brand name", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, email: "ze@example.com", password: "s3cr3t123") }

  def sign_in
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  describe "GET /owner/brand_name/edit" do
    it "shows the establishment address and does not remount it from the name" do
      create(:branding, tenant: tenant)
      sign_in

      get edit_owner_brand_name_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("barbearia-do-ze.zubio.com.br")
      expect(response.body).to include(%(<a href="#{owner_settings_path}" aria-current="page"))
    end

    it "sends an anonymous visitor to the login" do
      host! "#{tenant.subdomain}.zubio.com.br"

      get edit_owner_brand_name_path

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "PATCH /owner/brand_name" do
    it "stores a name at the limit" do
      sign_in

      patch owner_brand_name_path, params: { tenant: { name: "a" * Tenant::NAME_MAX_LENGTH } }

      expect(response).to redirect_to(edit_owner_brand_name_path)
      expect(tenant.reload.name).to eq("a" * Tenant::NAME_MAX_LENGTH)
    end

    it "refuses a name over the limit on the same screen, keeping the stored one" do
      sign_in

      patch owner_brand_name_path, params: { tenant: { name: "a" * (Tenant::NAME_MAX_LENGTH + 1) } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("text-danger")
      expect(tenant.reload.name).to eq("Barbearia do Zé")
    end

    it "states a blank name in Portuguese, without the default English" do
      sign_in

      patch owner_brand_name_path, params: { tenant: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("não pode ficar em branco")
      expect(response.body).not_to include("can't be blank")
    end

    it "keeps the address after a rename, since the subdomain does not change" do
      sign_in

      patch owner_brand_name_path, params: { tenant: { name: "Navalha Barber Club" } }
      follow_redirect!

      expect(response.body).to include("barbearia-do-ze.zubio.com.br")
    end

    it "renames a tenant that never saved a brand without failing on the missing branding" do
      sign_in

      patch owner_brand_name_path, params: { tenant: { name: "Navalha" } }

      expect(response).to redirect_to(edit_owner_brand_name_path)
      expect(tenant.reload.name).to eq("Navalha")
      ActsAsTenant.with_tenant(tenant) { expect(tenant.branding).to be_nil }
    end

    it "does not rename another establishment" do
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      sign_in

      patch owner_brand_name_path, params: { tenant: { name: "Hijacked" } }

      expect(tenant.reload.name).to eq("Hijacked")
      expect(other_tenant.reload.name).to eq("Estúdio Aurora")
    end
  end
end
