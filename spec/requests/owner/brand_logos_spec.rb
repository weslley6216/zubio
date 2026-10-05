require "rails_helper"

RSpec.describe "Owner brand logo", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, email: "ze@example.com", password: "s3cr3t123") }

  describe "GET /owner/brand_logo/edit" do
    it "shows the initial and both the gallery and the camera action when there is no logo" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)

      get edit_owner_brand_logo_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::GALLERY_LABEL)
      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::CAMERA_LABEL)
      expect(response.body).to include(">B</span>")
      expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
    end

    it "sends an anonymous visitor to the login" do
      host! "#{tenant.subdomain}.zubio.com.br"

      get edit_owner_brand_logo_path

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "PATCH /owner/brand_logo" do
    it "saves a valid logo and enqueues variant precomputation, leaving the name untouched" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)
      logo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.png"), "image/png")

      expect {
        patch owner_brand_logo_path, params: { branding: { logo: logo } }
      }.to have_enqueued_job(Branding::PrecomputeVariantsJob).with(tenant.id)

      expect(response).to redirect_to(edit_owner_brand_logo_path)
      ActsAsTenant.with_tenant(tenant) do
        expect(tenant.reload.branding.logo).to be_attached
        expect(tenant.name).to eq("Barbearia do Zé")
      end
    end

    it "removes the logo and shows the initial again" do
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)

      perform_enqueued_jobs do
        patch owner_brand_logo_path, params: { branding: { remove_logo: "1" } }
      end
      follow_redirect!

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo).not_to be_attached }
      expect(response.body).to include(">B</span>")
    end

    it "rejects an unsupported file type without attaching it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)
      pdf = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4 fake pdf content"), "application/pdf", original_filename: "logo.pdf")

      patch owner_brand_logo_path, params: { branding: { logo: pdf } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo).not_to be_attached }
    end

    it "does not touch another establishment's logo" do
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, :with_logo, tenant: other_tenant)
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)

      perform_enqueued_jobs do
        patch owner_brand_logo_path, params: { branding: { remove_logo: "1" } }
      end

      ActsAsTenant.with_tenant(tenant) { expect(tenant.branding.reload.logo).not_to be_attached }
      ActsAsTenant.with_tenant(other_tenant) { expect(other_tenant.branding.reload.logo).to be_attached }
    end

    it "rejects a file whose bytes are not an image, keeping the previous logo" do
      branding = create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      original_blob_id = ActsAsTenant.with_tenant(tenant) { branding.logo.blob.id }
      sign_in_owner(owner)
      fake_png = Rack::Test::UploadedFile.new(StringIO.new("not an image"), "image/png", original_filename: "logo.png")

      patch owner_brand_logo_path, params: { branding: { logo: fake_png } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo.blob.id).to eq(original_blob_id) }
    end

    it "does not touch another establishment's logo when it rejects a non-image" do
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      other_branding = create(:branding, :with_logo, tenant: other_tenant)
      other_blob_id = ActsAsTenant.with_tenant(other_tenant) { other_branding.logo.blob.id }
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)
      fake_png = Rack::Test::UploadedFile.new(StringIO.new("not an image"), "image/png", original_filename: "logo.png")

      patch owner_brand_logo_path, params: { branding: { logo: fake_png } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(other_tenant) { expect(other_tenant.branding.reload.logo.blob.id).to eq(other_blob_id) }
    end

    it "rejects an image over the pixel ceiling, keeping the previous logo" do
      branding = create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      original_blob_id = ActsAsTenant.with_tenant(tenant) { branding.logo.blob.id }
      sign_in_owner(owner)
      edge = Branding::LOGO_MAX_PIXELS + 1
      huge_png = Rack::Test::UploadedFile.new(StringIO.new(Vips::Image.black(edge, edge).pngsave_buffer), "image/png", original_filename: "logo.png")

      patch owner_brand_logo_path, params: { branding: { logo: huge_png } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo.blob.id).to eq(original_blob_id) }
    end

    it "does not touch another establishment's logo when it rejects an image over the pixel ceiling" do
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      other_branding = create(:branding, :with_logo, tenant: other_tenant)
      other_blob_id = ActsAsTenant.with_tenant(other_tenant) { other_branding.logo.blob.id }
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")
      sign_in_owner(owner)
      edge = Branding::LOGO_MAX_PIXELS + 1
      huge_png = Rack::Test::UploadedFile.new(StringIO.new(Vips::Image.black(edge, edge).pngsave_buffer), "image/png", original_filename: "logo.png")

      patch owner_brand_logo_path, params: { branding: { logo: huge_png } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(other_tenant) { expect(other_tenant.branding.reload.logo.blob.id).to eq(other_blob_id) }
    end
  end
end
