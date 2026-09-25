require "rails_helper"

RSpec.describe "Owner onboarding", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner, display_name: owner.name) }
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  def answers(name: "Barbearia do Zé", price: "90,00")
    {
      tenant: { name: name },
      branding: { brand_600: "#2F6FED" },
      services: [ { name: "Corte", duration_minutes: "45", price: price } ],
      working_hours: { weekdays: %w[2 3], opens_at: "09:00", closes_at: "18:00" }
    }
  end

  describe "GET /owner/onboarding" do
    it "renders welcome and the five questions in one document, only welcome visible" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).to include(Components::Owner::BrandQuestion::Colors::TITLE)
      expect(response.body).to include(Components::Owner::BrandQuestion::Name::TITLE)
      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::TITLE)
      expect(response.body).to include(%(data-onboarding-open-value="welcome"))
      expect(response.body).to include(%(data-onboarding-section="working_hours"))
    end

    it "carries no draft, so another device starts fresh with an empty name field" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).to include(%(name="tenant[name]"))
      expect(response.body).not_to include(%(name="tenant[name]" value=))
    end

    it "redirects an owner who already finished to the dashboard" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response).to redirect_to(owner_dashboard_path)
    end

    it "redirects an anonymous visitor to login" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_onboarding_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "does not show another tenant's brand or services" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      ActsAsTenant.with_tenant(other_tenant) { create(:service, tenant: other_tenant, name: "Massagem") }
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).not_to include("Estúdio Aurora")
      expect(response.body).not_to include("Massagem")
    end

    it "lists three welcome groups with the Zubio emblem and the estimated time" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).to include("Sua marca: nome, logo e cor")
      expect(response.body).to include("O que você cobra")
      expect(response.body).to include("Quando você atende")
      expect(response.body).to include(">z</span>")
      expect(response.body).to include("Leva menos de três minutos")
    end

    it "shows the derived address card with the emblem and the typed name on the name question" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).to include(%(data-brand-address-target="name"))
      expect(response.body).to include(%(data-brand-address-target="address"))
    end

    it "offers gallery, camera and skipping without a logo, explaining the initial on the logo question" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::GALLERY_LABEL)
      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::CAMERA_LABEL)
      expect(response.body).to include(Views::Owner::Onboarding::Document::SKIP_LABEL)
      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
    end

    it "explains the sob consulta hint on the services question" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_path

      expect(response.body).to include("sob consulta")
    end
  end

  describe "POST /owner/onboarding" do
    it "writes everything, enqueues the completion email and hands off to the derived host" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      expect { post owner_onboarding_path, params: answers }
        .to have_enqueued_mail(OwnerMailer, :completed)

      expect(tenant.reload).to have_attributes(name: "Barbearia do Zé", subdomain: "barbearia-do-ze")
      expect(tenant.onboarding_completed?).to be(true)
      expect(response.location).to start_with(owner_handoff_url(subdomain: "barbearia-do-ze"))
      expect(response.location).to include("token=")
    end

    it "hands out the suffixed address when the derived one collides, untouched neighbour" do
      create(:tenant, subdomain: "barbearia-do-ze")
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      post owner_onboarding_path, params: answers

      expect(tenant.reload.subdomain).to eq("barbearia-do-ze-2")
      expect(Tenant.find_by(subdomain: "barbearia-do-ze")).to be_present
    end

    it "refuses an unreadable price, writes nothing and reopens the services section filled" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      post owner_onboarding_path, params: answers(price: "abc")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(Service::PRICE_UNREADABLE_MESSAGE)
      expect(response.body).to include(%(data-onboarding-open-value="services"))
      expect(tenant.reload).to have_attributes(name: nil)
      expect(tenant.onboarding_completed?).to be(false)
      ActsAsTenant.with_tenant(tenant) { expect(Service.count).to eq(0) }
    end

    it "shows a submitted service with its formatted duration and price, with the new-service card below, when a later section fails" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      ActsAsTenant.with_tenant(other_tenant) { create(:service, tenant: other_tenant, name: "Massagem") }
      sign_in(tenant)

      post owner_onboarding_path, params: answers.merge(
        services: [ { name: "Corte na máquina", duration_minutes: "30", price: "45,00" } ],
        working_hours: { weekdays: %w[2], opens_at: "18:00", closes_at: "09:00" }
      )

      expect(response.body).to include("Corte na máquina")
      expect(response.body).to include("30 min")
      expect(response.body).to include(Service::Price.label(4_500))
      expect(response.body).to include(Views::Owner::Onboarding::Document::NEW_SERVICE_LABEL)
      expect(response.body).not_to include("Massagem")
      expect(response.body).not_to include("Estúdio Aurora")
    end

    it "does not write to another tenant" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      other_tenant = create(:tenant, :onboarding, subdomain: "other123abc456")
      sign_in(tenant)

      post owner_onboarding_path, params: answers

      expect(other_tenant.reload).to have_attributes(name: nil)
      ActsAsTenant.with_tenant(other_tenant) { expect(Service.count).to eq(0) }
    end

    it "refuses a blank brand name and reopens the name section" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      post owner_onboarding_path, params: answers(name: "")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(data-onboarding-open-value="name"))
      expect(tenant.reload.onboarding_completed?).to be(false)
    end

    it "refuses an unreadable brand color and reopens the colors section" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      post owner_onboarding_path, params: answers.merge(branding: { brand_600: "not-a-hex" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(data-onboarding-open-value="colors"))
      expect(tenant.reload.onboarding_completed?).to be(false)
    end

    it "refuses an unsupported logo file and reopens the logo section" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)
      pdf_file = Tempfile.new([ "logo", ".pdf" ])
      pdf_file.write("%PDF-1.4 fake pdf content")
      pdf_file.rewind

      post owner_onboarding_path, params: answers.merge(
        branding: { brand_600: "#2F6FED", logo: Rack::Test::UploadedFile.new(pdf_file.path, "application/pdf") }
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(data-onboarding-open-value="logo"))
      expect(tenant.reload.onboarding_completed?).to be(false)
    ensure
      pdf_file.close!
    end

    it "refuses a logo whose bytes are not an image and reopens the logo section" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)
      fake = Tempfile.new([ "logo", ".png" ])
      fake.write("not an image")
      fake.rewind

      post owner_onboarding_path, params: answers.merge(
        branding: { brand_600: "#2F6FED", logo: Rack::Test::UploadedFile.new(fake.path, "image/png") }
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(data-onboarding-open-value="logo"))
      expect(tenant.reload.onboarding_completed?).to be(false)
    ensure
      fake.close!
    end

    it "refuses a schedule that closes before it opens and reopens the working_hours section" do
      tenant = create(:tenant, :onboarding, subdomain: "abc123def456")
      sign_in(tenant)

      post owner_onboarding_path, params: answers.merge(working_hours: { weekdays: %w[2], opens_at: "18:00", closes_at: "09:00" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(data-onboarding-open-value="working_hours"))
      expect(tenant.reload.onboarding_completed?).to be(false)
    end
  end
end
