require "rails_helper"

RSpec.describe Tenant, type: :model do
  describe "subdomain" do
    it "is invalid without a subdomain" do
      tenant = build(:tenant, subdomain: nil)

      expect(tenant).not_to be_valid
    end

    it "is invalid with a reserved subdomain" do
      tenant = build(:tenant, subdomain: "admin")

      expect(tenant).not_to be_valid
    end

    it "is invalid with an uppercase subdomain" do
      tenant = build(:tenant, subdomain: "Barbershop")

      expect(tenant).not_to be_valid
    end

    it "is invalid with an underscore" do
      tenant = build(:tenant, subdomain: "joes_barbershop")

      expect(tenant).not_to be_valid
    end

    it "is invalid with a leading hyphen" do
      tenant = build(:tenant, subdomain: "-barbershop")

      expect(tenant).not_to be_valid
    end

    it "is invalid with fewer than 3 characters" do
      tenant = build(:tenant, subdomain: "ab")

      expect(tenant).not_to be_valid
    end

    it "is invalid with a duplicate subdomain" do
      create(:tenant, subdomain: "joes-barbershop")
      tenant = build(:tenant, subdomain: "joes-barbershop")

      expect(tenant).not_to be_valid
    end

    it "is valid with lowercase letters and a hyphen in the middle" do
      tenant = build(:tenant, subdomain: "joes-barbershop")

      expect(tenant).to be_valid
    end
  end

  describe "name" do
    it "is invalid without a name" do
      tenant = build(:tenant, name: nil)

      expect(tenant).not_to be_valid
    end
  end

  describe "status" do
    it "is active by default" do
      tenant = create(:tenant)

      expect(tenant).to be_active
    end
  end

  describe "#cache_key_prefix" do
    it "includes the tenant id and the branding's updated_at timestamp" do
      tenant = create(:tenant)
      branding = create(:branding, tenant: tenant)

      expect(tenant.cache_key_prefix).to eq("t/#{tenant.id}/#{branding.updated_at.to_i}")
    end

    it "omits the timestamp when the tenant has no branding" do
      tenant = create(:tenant)

      expect(tenant.cache_key_prefix).to eq("t/#{tenant.id}/")
    end

    it "differs between tenants" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)

      expect(tenant_a.cache_key_prefix).not_to eq(tenant_b.cache_key_prefix)
    end

    it "changes when the tenant's branding is updated" do
      tenant = create(:tenant)
      branding = create(:branding, tenant: tenant)
      prefix_before = tenant.cache_key_prefix

      branding.update_column(:updated_at, branding.updated_at + 1.hour)

      expect(tenant.reload.cache_key_prefix).not_to eq(prefix_before)
    end
  end

  describe "#branding_or_default" do
    it "returns the tenant's branding when present" do
      tenant = create(:tenant)
      branding = create(:branding, tenant: tenant)

      expect(tenant.branding_or_default).to eq(branding)
    end

    it "falls back to the platform default when the tenant has no branding" do
      tenant = create(:tenant)

      expect(tenant.branding_or_default.brand_600).to eq(Branding::DEFAULT_BRAND_600)
    end
  end

  describe "#update_branding!" do
    it "updates the tenant name and the branding attributes atomically" do
      tenant = create(:tenant, name: "Old Name")
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      tenant.update_branding!(tenant_attrs: { name: "New Name" }, branding_attrs: { brand_600: "#2F6FED" }, remove_logo: false)

      expect(tenant.reload.name).to eq("New Name")
      expect(tenant.branding.reload.brand_600).to eq("#2F6FED")
    end

    it "rolls back the tenant name change when the branding attributes are invalid" do
      tenant = create(:tenant, name: "Old Name")
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      expect {
        tenant.update_branding!(tenant_attrs: { name: "New Name" }, branding_attrs: { brand_600: "not-a-hex" }, remove_logo: false)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(tenant.reload.name).to eq("Old Name")
    end

    it "enqueues icon variant precomputation when a new logo is included" do
      tenant = create(:tenant)
      create(:branding, tenant: tenant)
      logo = fixture_file_upload("spec/fixtures/files/logo.png", "image/png")

      expect {
        tenant.update_branding!(tenant_attrs: { name: tenant.name }, branding_attrs: { brand_600: "#4F46E5", logo: logo }, remove_logo: false)
      }.to have_enqueued_job(Branding::PrecomputeIconVariantsJob).with(tenant.id)
    end

    it "does not enqueue icon variant precomputation when no logo is included" do
      tenant = create(:tenant)
      create(:branding, tenant: tenant)

      expect {
        tenant.update_branding!(tenant_attrs: { name: tenant.name }, branding_attrs: { brand_600: "#4F46E5" }, remove_logo: false)
      }.not_to have_enqueued_job(Branding::PrecomputeIconVariantsJob)
    end

    it "purges the current logo when remove_logo is true and no replacement is given" do
      tenant = create(:tenant)
      create(:branding, :with_logo, tenant: tenant)

      perform_enqueued_jobs do
        tenant.update_branding!(tenant_attrs: { name: tenant.name }, branding_attrs: { brand_600: "#4F46E5" }, remove_logo: true)
      end

      expect(tenant.branding.reload.logo).not_to be_attached
    end

    it "does not purge the logo when a replacement is uploaded even if remove_logo is true" do
      tenant = create(:tenant)
      create(:branding, :with_logo, tenant: tenant)
      logo = fixture_file_upload("spec/fixtures/files/logo.png", "image/png")

      perform_enqueued_jobs do
        tenant.update_branding!(tenant_attrs: { name: tenant.name }, branding_attrs: { brand_600: "#4F46E5", logo: logo }, remove_logo: true)
      end

      expect(tenant.branding.reload.logo).to be_attached
    end
  end

  describe "#manifest_identity" do
    it "derives the id from the subdomain" do
      tenant = create(:tenant, subdomain: "joes-barbershop")

      expect(tenant.manifest_identity[:id]).to eq("/?tenant=joes-barbershop")
    end

    it "uses the tenant name" do
      tenant = create(:tenant, name: "Barbearia do Zé")

      expect(tenant.manifest_identity[:name]).to eq("Barbearia do Zé")
    end

    it "truncates the short_name to 12 characters without an ellipsis" do
      tenant = create(:tenant, name: "Barbearia do Zé Cortes")

      expect(tenant.manifest_identity[:short_name]).to eq("Barbearia do")
    end

    it "sets standalone display and portrait orientation for installability" do
      tenant = create(:tenant)

      expect(tenant.manifest_identity[:display]).to eq("standalone")
      expect(tenant.manifest_identity[:orientation]).to eq("portrait")
    end

    it "differs between tenants" do
      tenant_a = create(:tenant, subdomain: "salon-a")
      tenant_b = create(:tenant, subdomain: "salon-b")

      expect(tenant_a.manifest_identity[:id]).not_to eq(tenant_b.manifest_identity[:id])
    end
  end
end
