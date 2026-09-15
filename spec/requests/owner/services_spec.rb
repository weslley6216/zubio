require "rails_helper"

RSpec.describe "Owner services catalog", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  def sign_in
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  def service_params(**overrides)
    { service: { name: "Corte feminino", description: "", duration_minutes: "45", price: "90,00" }.merge(overrides) }
  end

  def service_count = ActsAsTenant.without_tenant { Service.count }

  def field(name) = Nokogiri::HTML5(response.body).at_css(%([data-field="#{name}"]))

  def control(name) = field(name).at_css("input, textarea")

  def serve_error_pages_as_in_production
    allow(Rails.application).to receive(:env_config).and_wrap_original do |env_config|
      env_config.call.merge("action_dispatch.show_detailed_exceptions" => false)
    end
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
      expect(response.body.scan("data-description").size).to eq(1)
    end

    it "marks a service that is disabled" do
      create(:service, tenant: tenant, name: "Barba", active: false)
      sign_in

      get owner_services_path

      expect(response.body).to include("Barba")
      expect(response.body).to include(Views::Owner::Services::Index::DISABLED_LABEL)
    end

    it "leaves an active service unmarked" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).not_to include(Views::Owner::Services::Index::DISABLED_LABEL)
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

    it "offers the registration from the heading once the catalog has a service" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in

      get owner_services_path

      expect(response.body).to include(%(<a href="#{new_owner_service_path}" class="#{Views::Owner::Services::Index::ACTION_CLASS}">#{Views::Owner::Services::Index::NEW_LABEL}</a>))
      expect(response.body.scan(%(href="#{new_owner_service_path}")).size).to eq(1)
      expect(response.body).not_to include(Views::Owner::Services::Index::FIRST_LABEL)
    end

    it "offers the registration inside the empty state alone when there is no service yet" do
      sign_in

      get owner_services_path

      expect(response.body).to include(%(<a href="#{new_owner_service_path}" class="#{Views::Owner::Services::Index::ACTION_CLASS}">#{Views::Owner::Services::Index::FIRST_LABEL}</a>))
      expect(response.body.scan(%(href="#{new_owner_service_path}")).size).to eq(1)
      expect(response.body).not_to include(Views::Owner::Services::Index::NEW_LABEL)
    end

    it "opens the edit form from the name of every service" do
      beard_trim = create(:service, tenant: tenant, name: "Barba")
      haircut = create(:service, tenant: tenant, name: "Corte feminino")
      sign_in

      get owner_services_path

      expect(response.body).to include(%(<a href="#{edit_owner_service_path(beard_trim)}" class="#{Views::Owner::Services::Index::NAME_CLASS}">Barba</a>))
      expect(response.body).to include(%(<a href="#{edit_owner_service_path(haircut)}" class="#{Views::Owner::Services::Index::NAME_CLASS}">Corte feminino</a>))
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

    it "asks the database the same number of times for many services as for one" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in
      get owner_services_path
      single = count_queries { get owner_services_path }

      create_list(:service, 4, tenant: tenant)

      expect(single).to be_positive
      expect(count_queries { get owner_services_path }).to eq(single)
    end
  end

  describe "GET /owner/services/new" do
    it "opens an empty registration form in the owner form card, with the services section current" do
      sign_in

      get new_owner_service_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<h1 id="#{Components::Owner::FormCard::HEADING_ID}" class="#{Components::Owner::FormCard::TITLE_CLASS}">#{Views::Owner::Services::Form::NEW_TITLE}</h1>))
      expect(response.body).to include(%(action="#{owner_services_path}"))
      expect(response.body).to include(%(<a href="#{owner_services_path}" aria-current="page"))
      expect(response.body).to include(Views::Owner::Services::Form::CREATE_LABEL)
      expect(control("price")["value"]).to be_nil
    end

    it "requires every field but the description" do
      sign_in

      get new_owner_service_path

      expect(control("name")["required"]).not_to be_nil
      expect(control("duration_minutes")["required"]).not_to be_nil
      expect(control("price")["required"]).not_to be_nil
      expect(control("description")["required"]).to be_nil
      expect(control("description").name).to eq("textarea")
    end

    it "caps the name and the description at the lengths the model accepts" do
      sign_in

      get new_owner_service_path

      expect(control("name")["maxlength"]).to eq(Service::NAME_MAX_LENGTH.to_s)
      expect(control("description")["maxlength"]).to eq(Service::DESCRIPTION_MAX_LENGTH.to_s)
    end

    it "bounds the duration with the rule of the model and ties it to the hint that states it" do
      sign_in

      get new_owner_service_path

      expect(control("duration_minutes")["type"]).to eq("number")
      expect(control("duration_minutes")["min"]).to eq(Service::MIN_DURATION_MINUTES.to_s)
      expect(control("duration_minutes")["max"]).to eq(Service::MAX_DURATION_MINUTES.to_s)
      expect(control("duration_minutes")["step"]).to eq(Service::DURATION_STEP_MINUTES.to_s)
      expect(control("duration_minutes")["aria-describedby"]).to eq(Views::Owner::Services::Form::DURATION_HINT_ID)
      expect(field("duration_minutes").at_css("##{Views::Owner::Services::Form::DURATION_HINT_ID}").text).to eq("Múltiplos de 5 minutos, até 8 horas.")
    end

    it "opens a decimal keyboard for the price and ties it to the hint that shows the format" do
      sign_in

      get new_owner_service_path

      expect(control("price")["type"]).to eq("text")
      expect(control("price")["inputmode"]).to eq("decimal")
      expect(control("price")["aria-describedby"]).to eq(Views::Owner::Services::Form::PRICE_HINT_ID)
      expect(field("price").at_css("##{Views::Owner::Services::Form::PRICE_HINT_ID}").text).to eq(Views::Owner::Services::Form::PRICE_HINT)
    end

    it "sends an anonymous visitor to the login" do
      host! "#{tenant.subdomain}.zubio.com.br"

      get new_owner_service_path

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "POST /owner/services" do
    it "creates the service in the establishment of the host and lists it back on the catalog" do
      sign_in

      expect { post owner_services_path, params: service_params(description: "Inclui lavagem e finalização.") }.to change { service_count }.by(1)

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) do
        service = Service.find_by!(name: "Corte feminino")
        expect([ service.duration_minutes, service.price_cents, service.description ]).to eq([ 45, 9_000, "Inclui lavagem e finalização." ])
      end

      follow_redirect!

      expect(response.body).to include("Corte feminino")
      expect(response.body).to include("R$ 90,00")
      expect(response.body).to include("Serviço cadastrado.")
    end

    it "accepts a service without a description and stores none" do
      sign_in

      post owner_services_path, params: service_params(description: "")

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.find_by!(name: "Corte feminino").description).to be_nil }
    end

    it "refuses a duration off the five-minute steps and gives the form back with what was typed, the error beside the duration" do
      sign_in

      expect { post owner_services_path, params: service_params(duration_minutes: "7") }.not_to change { service_count }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(control("name")["value"]).to eq("Corte feminino")
      expect(control("duration_minutes")["value"]).to eq("7")
      expect(control("price")["value"]).to eq("90,00")
      expect(field("duration_minutes").text).to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
      expect(field("name").text).not_to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
    end

    it "states the refusal in the danger tone on the same screen" do
      sign_in

      post owner_services_path, params: service_params(duration_minutes: "7")

      expect(response.body).to include(Owner::ServicesController::REFUSED)
      expect(response.body).to include(%(class="#{Components::Alert::FRAME_CLASS} border-danger"))
      expect(response.body).not_to include("border-success")
    end

    it "refuses a duration with a fraction sent straight to the server" do
      sign_in

      expect { post owner_services_path, params: service_params(duration_minutes: "45.5") }.not_to change { service_count }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field("duration_minutes").text).to include(Service::DURATION_NOT_WHOLE_MESSAGE)
    end

    it "refuses a name the establishment already uses, with the error beside the name" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in

      expect { post owner_services_path, params: service_params }.not_to change { service_count }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field("name").text).to include(Service::NAME_TAKEN_MESSAGE)
      expect(field("duration_minutes").text).not_to include(Service::NAME_TAKEN_MESSAGE)
    end

    it "accepts a name another establishment already uses" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:service, tenant: other_tenant, name: "Corte feminino")
      sign_in

      post owner_services_path, params: service_params

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.pluck(:name)).to eq([ "Corte feminino" ]) }
    end

    it "refuses a price it cannot read instead of storing it as zero" do
      sign_in

      expect { post owner_services_path, params: service_params(price: "noventa") }.not_to change { service_count }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(control("price")["value"]).to eq("noventa")
      expect(field("price").text).to include(Service::PRICE_UNREADABLE_MESSAGE)
    end

    it "answers a price above what the column holds with the form instead of a server error" do
      sign_in

      expect { post owner_services_path, params: service_params(price: "30.000.000,00") }.not_to change { service_count }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field("price").text).to include(Service::PRICE_OUT_OF_RANGE_MESSAGE)
    end

    it "answers a name longer than the index holds with the form instead of a server error" do
      sign_in

      expect { post owner_services_path, params: service_params(name: "a" * 3_000) }.not_to change { service_count }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field("name").text).to include(Service::NAME_TOO_LONG_MESSAGE)
    end

    it "creates the service in the establishment of the host even when the body names another one" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      sign_in

      post owner_services_path, params: service_params(tenant_id: other_tenant.id)

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.pluck(:name)).to eq([ "Corte feminino" ]) }
      ActsAsTenant.with_tenant(other_tenant) { expect(Service.count).to eq(0) }
    end

    it "sends an anonymous visitor to the login without creating anything" do
      host! "#{tenant.subdomain}.zubio.com.br"

      expect { post owner_services_path, params: service_params }.not_to change { service_count }

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "GET /owner/services/:id/edit" do
    it "opens the form filled with what the service stores" do
      service = create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      sign_in

      get edit_owner_service_path(service)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{owner_service_path(service)}"))
      expect(response.body).to include(Views::Owner::Services::Form::EDIT_TITLE)
      expect(response.body).to include(Views::Owner::Services::Form::UPDATE_LABEL)
      expect(control("name")["value"]).to eq("Corte feminino")
      expect(control("duration_minutes")["value"]).to eq("45")
      expect(control("price")["value"]).to eq("90,00")
    end

    it "opens the form for a disabled service too" do
      service = create(:service, tenant: tenant, name: "Barba", active: false)
      sign_in

      get edit_owner_service_path(service)

      expect(response).to have_http_status(:ok)
      expect(control("name")["value"]).to eq("Barba")
    end

    it "answers not found for the service of another establishment, with none of its data" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      other_service = create(:service, tenant: other_tenant, name: "Barba do Zé", description: "Navalha e toalha quente.")
      sign_in
      serve_error_pages_as_in_production

      get edit_owner_service_path(other_service)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Barba do Zé")
      expect(response.body).not_to include("Navalha e toalha quente.")
    end

    it "sends an anonymous visitor to the login from the edit form" do
      service = create(:service, tenant: tenant, name: "Corte feminino")
      host! "#{tenant.subdomain}.zubio.com.br"

      get edit_owner_service_path(service)

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "PATCH /owner/services/:id" do
    it "changes the price and goes back to the catalog" do
      service = create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      sign_in

      patch owner_service_path(service), params: service_params(price: "100,00")

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.price_cents).to eq(10_000) }

      follow_redirect!

      expect(response.body).to include("Serviço atualizado.")
      expect(response.body).to include("R$ 100,00")
    end

    it "keeps the stored duration when the new one is out of range, with the error beside the duration" do
      service = create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      sign_in

      patch owner_service_path(service), params: service_params(duration_minutes: "600")

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.duration_minutes).to eq(45) }
      expect(control("duration_minutes")["value"]).to eq("600")
      expect(field("duration_minutes").text).to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
      expect(field("price").text).not_to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
      expect(response.body).to include(Owner::ServicesController::REFUSED)
    end

    it "leaves the service of another establishment untouched and answers not found" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      other_service = create(:service, tenant: other_tenant, name: "Barba do Zé", price_cents: 5_000)
      sign_in

      patch owner_service_path(other_service), params: service_params(name: "Hijacked", price: "1,00")

      expect(response).to have_http_status(:not_found)
      ActsAsTenant.with_tenant(other_tenant) do
        expect(other_service.reload.name).to eq("Barba do Zé")
        expect(other_service.price_cents).to eq(5_000)
      end
    end

    it "sends an anonymous visitor to the login without changing the service" do
      service = create(:service, tenant: tenant, name: "Corte feminino", price_cents: 9_000)
      host! "#{tenant.subdomain}.zubio.com.br"

      patch owner_service_path(service), params: service_params(price: "1,00")

      expect(response).to redirect_to(new_owner_session_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.price_cents).to eq(9_000) }
    end
  end
end
