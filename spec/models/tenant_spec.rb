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

  describe ".provision!" do
    it "creates a tenant and an owner user" do
      tenant = Tenant.provision!(
        tenant_attributes: { name: "Studio Aurora", subdomain: "estudio-aurora" },
        owner_attributes: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123", password_confirmation: "s3cr3t123" }
      )

      expect(tenant).to be_persisted
      expect(tenant.users.sole).to be_owner
    end

    it "rolls back the tenant when the owner attributes are invalid" do
      expect {
        Tenant.provision!(
          tenant_attributes: { name: "Studio Aurora", subdomain: "estudio-aurora" },
          owner_attributes: { name: "Ana Lima", email: "ana@example.com", password: "", password_confirmation: "" }
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
        .and change(Tenant, :count).by(0)
        .and change(User, :count).by(0)
    end

    it "raises for a duplicate subdomain without creating a user" do
      create(:tenant, subdomain: "estudio-aurora")

      expect {
        Tenant.provision!(
          tenant_attributes: { name: "Studio Aurora 2", subdomain: "estudio-aurora" },
          owner_attributes: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123", password_confirmation: "s3cr3t123" }
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
        .and change(User, :count).by(0)
    end
  end

  describe "custom_domain" do
    it "is valid with a well-formed custom domain" do
      tenant = build(:tenant, custom_domain: "barbeariadoze.com.br")

      expect(tenant).to be_valid
    end

    it "is invalid with a malformed custom domain" do
      tenant = build(:tenant, custom_domain: "not a domain")

      expect(tenant).not_to be_valid
    end

    it "is invalid with a custom domain already used by another tenant" do
      create(:tenant, custom_domain: "barbeariadoze.com.br")
      tenant = build(:tenant, custom_domain: "barbeariadoze.com.br")

      expect(tenant).not_to be_valid
    end

    it "is invalid when the custom domain is a subdomain of the platform host" do
      tenant = build(:tenant, custom_domain: "sub.#{Tenant::PLATFORM_HOST}")

      expect(tenant).not_to be_valid
    end

    it "is invalid when the custom domain is a subdomain of the platform host in a different case" do
      tenant = build(:tenant, custom_domain: "SUB.#{Tenant::PLATFORM_HOST.upcase}")

      expect(tenant).not_to be_valid
    end
  end

  describe "#register_custom_domain!" do
    it "stores the custom domain and the Cloudflare verification record" do
      tenant = create(:tenant)
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames")
        .to_return(
          status: 200,
          body: {
            result: {
              id: "cf-hostname-id",
              status: "pending",
              ownership_verification: { name: "_cf-custom-hostname.barbeariadoze.com.br", value: "cf-verification-token" }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      tenant.register_custom_domain!("barbeariadoze.com.br")

      expect(tenant.reload).to have_attributes(
        custom_domain: "barbeariadoze.com.br",
        custom_domain_cloudflare_id: "cf-hostname-id",
        custom_domain_verification_txt_name: "_cf-custom-hostname.barbeariadoze.com.br",
        custom_domain_verification_txt_value: "cf-verification-token",
        custom_domain_verified_at: nil
      )
    end

    it "resets verification and deletes the previous Cloudflare hostname when the domain changes to a new one" do
      tenant = create(:tenant, :with_verified_custom_domain)
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames")
        .to_return(
          status: 200,
          body: {
            result: {
              id: "cf-hostname-id-2",
              status: "pending",
              ownership_verification: { name: "_cf-custom-hostname.novadominio.com.br", value: "cf-verification-token-2" }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      delete_stub = stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
        .to_return(status: 200, body: { result: { id: "cf-hostname-id" } }.to_json, headers: { "Content-Type" => "application/json" })

      tenant.register_custom_domain!("novadominio.com.br")

      expect(tenant.reload.custom_domain_verified_at).to be_nil
      expect(delete_stub).to have_been_requested
    end

    it "does nothing when the submitted domain is already the tenant's current domain" do
      tenant = create(:tenant, :with_verified_custom_domain)

      tenant.register_custom_domain!(tenant.custom_domain)

      expect(tenant.reload.custom_domain_verified_at).to be_present
      expect(WebMock).not_to have_requested(:post, /api\.cloudflare\.com/)
    end

    it "raises without calling the Cloudflare API when the domain is invalid" do
      tenant = create(:tenant)

      expect { tenant.register_custom_domain!("not a domain") }.to raise_error(ActiveRecord::RecordInvalid)

      expect(WebMock).not_to have_requested(:post, /api\.cloudflare\.com/)
    end

    it "raises RecordNotUnique when the database index catches a domain claimed by another tenant after in-memory validation passed" do
      tenant = create(:tenant)
      other_tenant = create(:tenant)
      other_tenant.update_column(:custom_domain, "barbeariadoze.com.br")
      allow(tenant).to receive(:valid?).and_return(true)
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames")
        .to_return(
          status: 200,
          body: {
            result: {
              id: "cf-hostname-id",
              status: "pending",
              ownership_verification: { name: "_cf-custom-hostname.barbeariadoze.com.br", value: "cf-verification-token" }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { tenant.register_custom_domain!("barbeariadoze.com.br") }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#remove_custom_domain!" do
    it "clears the custom domain and deletes the Cloudflare hostname" do
      tenant = create(:tenant, :with_verified_custom_domain)
      delete_stub = stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
        .to_return(status: 200, body: { result: { id: "cf-hostname-id" } }.to_json, headers: { "Content-Type" => "application/json" })

      tenant.remove_custom_domain!

      expect(tenant.reload).to have_attributes(
        custom_domain: nil,
        custom_domain_cloudflare_id: nil,
        custom_domain_verification_txt_name: nil,
        custom_domain_verification_txt_value: nil,
        custom_domain_verified_at: nil
      )
      expect(delete_stub).to have_been_requested
    end
  end

  describe "#check_custom_domain_verification!" do
    it "marks the domain verified when Cloudflare reports the hostname active" do
      tenant = create(:tenant, :with_pending_custom_domain)
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
        .to_return(status: 200, body: { result: { status: "active" } }.to_json, headers: { "Content-Type" => "application/json" })

      tenant.check_custom_domain_verification!

      expect(tenant.reload.custom_domain_verified_at).to be_present
    end

    it "leaves the domain pending when Cloudflare reports the hostname still pending" do
      tenant = create(:tenant, :with_pending_custom_domain)
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
        .to_return(status: 200, body: { result: { status: "pending" } }.to_json, headers: { "Content-Type" => "application/json" })

      tenant.check_custom_domain_verification!

      expect(tenant.reload.custom_domain_verified_at).to be_nil
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
