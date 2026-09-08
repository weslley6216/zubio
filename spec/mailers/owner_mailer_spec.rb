require "rails_helper"

RSpec.describe OwnerMailer, type: :mailer do
  describe "#welcome" do
    let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Studio Aurora") }
    let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", role: "owner") }

    it "is addressed to the owner who has just signed up" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.to).to eq([ "ana@example.com" ])
    end

    it "names the establishment in the subject" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.subject).to eq("Studio Aurora está no ar no Zubio")
    end

    it "is delivered as plain text" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.mime_type).to eq("text/plain")
    end

    it "carries the address of the establishment the owner has just created" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.body.to_s).to include("estudio-aurora.zubio.com.br/owner/session/new")
    end

    it "greets the owner by name" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.body.to_s).to include("Ana Lima")
    end

    it "prefers the verified custom domain over the subdomain" do
      tenant.update!(custom_domain: "barbeariadoze.com.br", custom_domain_verified_at: Time.current)

      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.body.to_s).to include("barbeariadoze.com.br/owner/session/new")
    end

    it "refuses to render an owner who belongs to another tenant" do
      other_owner = create(:user, tenant: create(:tenant, subdomain: "salon-b"), role: "owner")

      expect { described_class.welcome(tenant.id, other_owner.id).message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
