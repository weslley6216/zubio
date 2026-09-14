require "rails_helper"

RSpec.describe "Owner services catalog", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  def sign_in
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  describe "GET /owner/services" do
    it "lists every service of the establishment with its duration and its price" do
      create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      create(:service, tenant: tenant, name: "Coloração completa", duration_minutes: 120, price_cents: 25_000)
      sign_in

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).to include("45 min")
      expect(response.body).to include("R$ 90,00")
      expect(response.body).to include("Coloração completa")
      expect(response.body).to include("120 min")
      expect(response.body).to include("R$ 250,00")
    end

    it "shows the description of a service that has one" do
      create(:service, tenant: tenant, name: "Corte feminino", description: "Inclui lavagem e finalização.")
      sign_in

      get owner_services_path

      expect(response.body).to include("Inclui lavagem e finalização.")
    end

    it "leaves no description line behind for a service without one" do
      create(:service, tenant: tenant, name: "Corte feminino", description: "Inclui lavagem e finalização.")
      create(:service, tenant: tenant, name: "Barba", description: nil)
      sign_in

      get owner_services_path

      expect(response.body).to include("Barba")
      expect(response.body.scan(Views::Owner::Services::Index::DESCRIPTION_CLASS).size).to eq(1)
    end

    it "marks the disabled service and leaves the active one unmarked" do
      create(:service, tenant: tenant, name: "Corte feminino")
      create(:service, tenant: tenant, name: "Barba", active: false)
      sign_in

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).to include("Barba")
      expect(response.body.scan(Views::Owner::Services::Index::DISABLED_LABEL).size).to eq(1)
    end

    it "invites the first registration when there is no service yet" do
      sign_in

      get owner_services_path

      expect(response.body).to include(Views::Owner::Services::Index::EMPTY_TITLE)
      expect(response.body).to include(Views::Owner::Services::Index::EMPTY_BODY)
      expect(response.body).not_to include("data-catalog")
    end

    it "drops the invitation once the catalog has a service" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).to include("data-catalog")
      expect(response.body).not_to include(Views::Owner::Services::Index::EMPTY_TITLE)
    end

    it "sends an anonymous visitor to the login without naming a service" do
      create(:service, tenant: tenant, name: "Corte feminino")
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_services_path

      expect(response).to redirect_to(new_owner_session_path)

      follow_redirect!

      expect(response.body).not_to include("Corte feminino")
    end

    it "lists the services of the establishment in the host and none of another one" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      create(:service, tenant: other_tenant, name: "Barba do Zé")
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).not_to include("Barba do Zé")
    end
  end
end
