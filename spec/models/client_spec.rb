require "rails_helper"

RSpec.describe Client, type: :model do
  describe "validations" do
    it "persists a valid client in the current tenant with a digits-only phone" do
      tenant = create(:tenant)
      client = build(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "(11) 98877-6655")

      ActsAsTenant.with_tenant(tenant) { client.save }

      expect(client).to be_persisted
      expect(client.tenant).to eq(tenant)
      expect(client.phone).to eq("11988776655")
    end

    it "is invalid with a punctuation variant of an existing number in the same tenant" do
      tenant = create(:tenant)
      create(:client, tenant: tenant, phone: "11988776655")
      duplicate = build(:client, tenant: tenant, phone: "(11) 98877-6655")

      duplicate.valid?

      expect(duplicate.errors[:phone]).to be_present
    end

    it "normalizes a country-code number to the same form and collides with the plain one" do
      tenant = create(:tenant)
      create(:client, tenant: tenant, phone: "+55 (11) 98877-6655")
      plain = build(:client, tenant: tenant, phone: "11988776655")

      plain.valid?

      expect(plain.errors[:phone]).to be_present
    end

    it "preserves a DDD-55 number instead of stripping it as a country code" do
      tenant = create(:tenant)
      client = build(:client, tenant: tenant, phone: "55988776655")

      ActsAsTenant.with_tenant(tenant) { client.save }

      expect(client).to be_persisted
      expect(client.phone).to eq("55988776655")
    end

    it "is valid with the same phone in a different tenant" do
      create(:client, phone: "11988776655")
      other = build(:client, phone: "11988776655")

      expect(other).to be_valid
    end

    it "is invalid with a phone too short to be a phone" do
      client = build(:client, phone: "1198877")

      client.valid?

      expect(client.errors[:phone]).to be_present
    end

    it "accepts ten and eleven digit phones" do
      ten = build(:client, phone: "1188776655")
      eleven = build(:client, phone: "11988776655")

      expect(ten).to be_valid
      expect(eleven).to be_valid
    end

    it "is invalid without a name" do
      client = build(:client, name: nil)

      client.valid?

      expect(client.errors[:name]).to be_present
    end
  end

  describe ".register" do
    it "register reuses the client by phone and updates the name" do
      tenant = create(:tenant)
      existing = create(:client, tenant: tenant, name: "Ana Ribeiro", phone: "11988776655")

      result = ActsAsTenant.with_tenant(tenant) { Client.register(name: "Ana Paula Ribeiro", phone: "(11) 98877-6655") }

      expect(result).to eq(existing)
      expect(result.reload.name).to eq("Ana Paula Ribeiro")
      expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
    end

    it "register in one tenant does not reuse another tenant's client with the same phone" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      ze = create(:tenant, name: "Barbearia do Zé")
      create(:client, tenant: aurora, name: "Ana Aurora", phone: "11988776655")

      registered = ActsAsTenant.with_tenant(ze) { Client.register(name: "Ana Zé", phone: "11988776655") }

      expect(registered).to be_persisted
      expect(registered.tenant).to eq(ze)
      expect(registered.name).to eq("Ana Zé")
    end
  end

  describe "#phone_display" do
    it "formats an eleven-digit mobile number" do
      client = build(:client, phone: "11988771234")

      expect(client.phone_display).to eq("(11) 98877-1234")
    end

    it "formats a ten-digit landline number" do
      client = build(:client, phone: "1133224455")

      expect(client.phone_display).to eq("(11) 3322-4455")
    end
  end

  describe "#tel_href" do
    it "builds a call link with the country code" do
      client = build(:client, phone: "11988771234")

      expect(client.tel_href).to eq("tel:+5511988771234")
    end

    it "dials the masked phone in E.164" do
      client = create(:client, phone: "(11) 98877-1234")

      expect(client.tel_href).to eq("tel:+5511988771234")
    end
  end

  describe "#whatsapp_url" do
    it "builds the WhatsApp address in E.164 with the 55 country code" do
      client = create(:client, phone: "11988771234")

      expect(client.whatsapp_url).to eq("https://wa.me/5511988771234")
    end

    it "builds the same WhatsApp address from a masked phone" do
      client = create(:client, phone: "(11) 98877-1234")

      expect(client.whatsapp_url).to eq("https://wa.me/5511988771234")
    end

    it "builds the WhatsApp address from a phone typed with the country code" do
      client = create(:client, phone: "+55 11 98877-1234")

      expect(client.whatsapp_url).to eq("https://wa.me/5511988771234")
    end

    it "builds the WhatsApp address for a ten-digit landline" do
      client = create(:client, phone: "1133334444")

      expect(client.whatsapp_url).to eq("https://wa.me/551133334444")
    end
  end

  describe "#initials" do
    it "takes the initials of the first two names" do
      client = build(:client, name: "Ana Paula Ribeiro")

      expect(client.initials).to eq("AP")
    end

    it "takes a single initial for a one-word name" do
      client = build(:client, name: "maria")

      expect(client.initials).to eq("M")
    end
  end

  describe ".link_google!" do
    it "links a brand-new account to a brand-new phone and stamps account_linked_at" do
      tenant = create(:tenant)

      client = ActsAsTenant.with_tenant(tenant) do
        Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana Paula Ribeiro", phone: "(11) 98877-1234")
      end

      expect(client).to be_persisted
      expect(client.google_uid).to eq("g-1")
      expect(client.account_linked_at).to be_present
      expect(client.phone).to eq("11988771234")
    end

    it "reuses the phone-only client and attaches the Google account" do
      tenant = create(:tenant)
      existing = create(:client, tenant: tenant, name: "Ana", phone: "11988771234")

      client = ActsAsTenant.with_tenant(tenant) do
        Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana Paula Ribeiro", phone: "11988771234")
      end

      expect(client.id).to eq(existing.id)
      expect(client.name).to eq("Ana Paula Ribeiro")
      expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
    end

    it "refuses a phone already linked to a different Google account" do
      tenant = create(:tenant)
      ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-A", email: "a@gmail.com", name: "A", phone: "11988771234") }

      client = ActsAsTenant.with_tenant(tenant) do
        Client.link_google!(uid: "g-B", email: "b@gmail.com", name: "B", phone: "11988771234")
      end

      expect(client).not_to be_persisted
      expect(client.errors[:phone]).to include(Client::PHONE_TAKEN_MESSAGE)
      expect(ActsAsTenant.with_tenant(tenant) { Client.where(google_uid: "g-B") }).to be_empty
    end

    it "allows the same google_uid in a different tenant as a separate link" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      ze = create(:tenant, name: "Barbearia do Zé")
      ActsAsTenant.with_tenant(aurora) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "11988771234") }

      ze_client = ActsAsTenant.with_tenant(ze) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "21977665544") }

      expect(ze_client).to be_persisted
      expect(ze_client.tenant).to eq(ze)
      own_tenant_uids = ActsAsTenant.with_tenant(ze) { Client.pluck(:google_uid) }
      expect(own_tenant_uids).to include("g-1")
    end

    it "is invalid with two clients sharing a google_uid in the same tenant" do
      tenant = create(:tenant)
      create(:client, tenant: tenant, phone: "11988771234", google_uid: "g-1")
      duplicate = build(:client, tenant: tenant, phone: "21977665544", google_uid: "g-1")

      duplicate.valid?

      expect(duplicate.errors[:google_uid]).to be_present
    end

    it "is valid with two clients both lacking a google_uid in the same tenant" do
      tenant = create(:tenant)
      create(:client, tenant: tenant, phone: "11988771234")
      other = build(:client, tenant: tenant, phone: "21977665544")

      expect(other).to be_valid
    end
  end

  describe "handoff token" do
    it "mints a one-time handoff token the second use rejects" do
      tenant = create(:tenant)
      client = create(:client, tenant: tenant)

      token = client.handoff_token
      found = ActsAsTenant.with_tenant(tenant) { Client.find_by_handoff_token(token) }
      client.consume_handoff_token!
      found_again = ActsAsTenant.with_tenant(tenant) { Client.find_by_handoff_token(token) }

      expect(found).to eq(client)
      expect(found_again).to be_nil
    end

    it "does not find a handoff token minted in another tenant" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      ze = create(:tenant, name: "Barbearia do Zé")
      client = create(:client, tenant: aurora)
      token = client.handoff_token

      found_in_aurora = ActsAsTenant.with_tenant(aurora) { Client.find_by_handoff_token(token) }
      found_in_ze = ActsAsTenant.with_tenant(ze) { Client.find_by_handoff_token(token) }

      expect(found_in_aurora).to eq(client)
      expect(found_in_ze).to be_nil
    end
  end

  describe "tenant isolation" do
    it "a scoped query brings the tenant's own client and not another's" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      ze = create(:tenant, name: "Barbearia do Zé")
      create(:client, tenant: aurora, name: "Ana Aurora", phone: "11988776655")
      create(:client, tenant: ze, name: "Bia Zé", phone: "21977665544")

      names = ActsAsTenant.with_tenant(aurora) { Client.pluck(:name) }

      expect(names).to include("Ana Aurora")
      expect(names).not_to include("Bia Zé")
    end
  end
end
