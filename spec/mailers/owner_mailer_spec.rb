require "rails_helper"

RSpec.describe OwnerMailer, type: :mailer do
  describe "#welcome" do
    let(:tenant) { create(:tenant, :onboarding, subdomain: "abc123def456") }
    let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", role: "owner") }

    it "is addressed to the owner who has just signed up" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.to).to eq([ "ana@example.com" ])
    end

    it "does not name any establishment in the subject" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.subject).to eq("Sua conta no Zubio está pronta")
    end

    it "is delivered as plain text" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.mime_type).to eq("text/plain")
    end

    it "carries the provisional host the owner logs back in through" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.body.to_s).to include("abc123def456.zubio.com.br/owner/session/new")
    end

    it "greets the owner by name" do
      mail = described_class.welcome(tenant.id, owner.id)

      expect(mail.body.to_s).to include("Ana Lima")
    end

    it "refuses to render an owner who belongs to another tenant" do
      other_owner = create(:user, tenant: create(:tenant, subdomain: "salon-b"), role: "owner")

      expect { described_class.welcome(tenant.id, other_owner.id).message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
