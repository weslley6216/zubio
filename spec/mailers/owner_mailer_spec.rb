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

  describe "#completed" do
    let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
    let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", role: "owner") }

    it "is addressed to the owner who just finished onboarding" do
      mail = described_class.completed(tenant.id, owner.id)

      expect(mail.to).to eq([ "ana@example.com" ])
    end

    it "announces the page is live in the subject" do
      mail = described_class.completed(tenant.id, owner.id)

      expect(mail.subject).to eq("Sua página está no ar no Zubio")
    end

    it "carries the establishment's final address" do
      mail = described_class.completed(tenant.id, owner.id)

      expect(mail.body.to_s).to include("barbearia-do-ze.zubio.com.br")
    end

    it "greets the owner by name" do
      mail = described_class.completed(tenant.id, owner.id)

      expect(mail.body.to_s).to include("Ana Lima")
    end

    it "is delivered as plain text" do
      mail = described_class.completed(tenant.id, owner.id)

      expect(mail.mime_type).to eq("text/plain")
    end

    it "refuses to render an owner who belongs to another tenant" do
      other_owner = create(:user, tenant: create(:tenant, subdomain: "salon-b"), role: "owner")

      expect { described_class.completed(tenant.id, other_owner.id).message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#password_reset" do
    let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
    let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", role: "owner") }

    it "is addressed to the owner who asked for it" do
      mail = described_class.password_reset(tenant.id, owner.id, "reset-token")

      expect(mail.to).to eq([ "ana@example.com" ])
    end

    it "names the password reset in the subject" do
      mail = described_class.password_reset(tenant.id, owner.id, "reset-token")

      expect(mail.subject).to eq("Recuperação de senha no Zubio")
    end

    it "is delivered as plain text" do
      mail = described_class.password_reset(tenant.id, owner.id, "reset-token")

      expect(mail.mime_type).to eq("text/plain")
    end

    it "carries the reset link on the establishment's host" do
      mail = described_class.password_reset(tenant.id, owner.id, "reset-token")

      expect(mail.body.to_s).to include("barbearia-do-ze.zubio.com.br/owner/password_reset/edit?token=reset-token")
    end

    it "warns that only the latest link works" do
      mail = described_class.password_reset(tenant.id, owner.id, "reset-token")

      expect(mail.body.to_s).to include("só o link mais recente funciona")
    end

    it "greets the owner by name" do
      mail = described_class.password_reset(tenant.id, owner.id, "reset-token")

      expect(mail.body.to_s).to include("Ana Lima")
    end

    it "refuses to render an owner who belongs to another tenant" do
      other_owner = create(:user, tenant: create(:tenant, subdomain: "salon-b"), role: "owner")

      expect { described_class.password_reset(tenant.id, other_owner.id, "reset-token").message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#new_appointment" do
    let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
    let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", role: "owner") }
    let(:appointment) do
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas")
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
        starts_at: Time.zone.local(2026, 11, 10, 9, 0))
    end

    it "is addressed to the establishment's owner" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.to).to eq([ "ana@example.com" ])
    end

    it "names the client and her phone number" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("Ana Paula Ribeiro")
      expect(mail.body.to_s).to include("11988771234")
    end

    it "carries the day and time of the appointment" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("10/11/2026")
      expect(mail.body.to_s).to include("09:00")
    end

    it "names the booked service" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("Design de sobrancelhas")
    end

    it "greets the owner by name" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("Ana Lima")
    end

    it "does not name the client in the subject" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.subject).to eq("Novo agendamento")
    end

    it "is delivered as plain text" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.mime_type).to eq("text/plain")
    end

    it "points to the owner dashboard on the establishment's host" do
      owner
      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("estudio-aurora.zubio.com.br/owner/dashboard")
    end

    it "addresses only the appointment tenant's owner, never another tenant's" do
      owner
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:user, tenant: ze, email: "ze@example.com", role: "owner")

      mail = described_class.new_appointment(tenant.id, appointment.id)

      expect(mail.to).to eq([ "ana@example.com" ])
    end

    it "cannot be built from an appointment id outside the given tenant" do
      owner
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ze_appointment = create(:appointment, tenant: ze)

      expect { described_class.new_appointment(tenant.id, ze_appointment.id).message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#login_links" do
    it "is addressed to the queried email and delivered as plain text" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:user, tenant: tenant, email: "ze@example.com", role: "owner")

      mail = described_class.login_links("ze@example.com")

      expect(mail.to).to eq([ "ze@example.com" ])
      expect(mail.mime_type).to eq("text/plain")
    end

    it "carries the tenant login link with the email already in the prefill parameter" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:user, tenant: tenant, email: "ze@example.com", role: "owner")

      mail = described_class.login_links("ze@example.com")

      expect(mail.body.to_s).to include("barbearia-do-ze.zubio.com.br/owner/session/new?email=ze%40example.com")
    end

    it "lists one link per establishment the address owns" do
      first_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      second_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:user, tenant: first_tenant, email: "ze@example.com", role: "owner")
      create(:user, tenant: second_tenant, email: "ze@example.com", role: "owner")

      body = described_class.login_links("ze@example.com").body.to_s

      expect(body).to include("barbearia-do-ze.zubio.com.br/owner/session/new")
      expect(body).to include("estudio-aurora.zubio.com.br/owner/session/new")
    end

    it "falls back to the host as the label for a tenant still without a name" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      create(:user, tenant: tenant, email: "ze@example.com", role: "owner")

      body = described_class.login_links("ze@example.com").body.to_s

      expect(body).to include("abc123def456.zubio.com.br")
      expect(body).not_to include("nil")
    end

    it "names only the queried address's establishments, never another owner's" do
      ze_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ana_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:user, tenant: ze_tenant, email: "ze@example.com", role: "owner")
      create(:user, tenant: ana_tenant, email: "ana@example.com", role: "owner")

      body = described_class.login_links("ze@example.com").body.to_s

      expect(body).to include("Barbearia do Zé")
      expect(body).not_to include("Estúdio Aurora")
    end

    it "delivers nothing when no owner matches the address" do
      expect(described_class.login_links("nobody@example.com").message.to).to be_nil
    end
  end
end
