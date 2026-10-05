require "rails_helper"

RSpec.describe "Owner services catalog", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  let(:service_fields) { { name: "Corte feminino", description: "", duration_minutes: "45", price: "90,00" } }

  describe "GET /owner/services" do
    it "offers the way back to settings above the heading, as the brand screens do" do
      sign_in_owner(owner)

      get owner_services_path

      back = Nokogiri::HTML5(response.body).at_css("main a[href='#{owner_settings_path}']")
      expect(back).to be_present
      expect(back.text).to include(Components::Owner::SettingsBackLink::LABEL)
    end

    it "lists every service of the establishment with its duration and its price" do
      create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      create(:service, tenant: tenant, name: "Coloração completa", duration_minutes: 120, price_cents: 25_000)
      sign_in_owner(owner)

      get owner_services_path

      document = Nokogiri::HTML5(response.body)
      expect(response.body).to include("Corte feminino")
      expect(document.css("[data-catalog] span").map(&:text)).to include("45min", "R$ 90,00")
      expect(response.body).to include("Coloração completa")
      expect(document.css("[data-catalog] span").map(&:text)).to include("2h", "R$ 250,00")
    end

    it "renders a sixty-minute service as 1h and its price in full" do
      create(:service, tenant: tenant, name: "Corte", duration_minutes: 60, price_cents: 8_000)
      sign_in_owner(owner)

      get owner_services_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-catalog] span").map(&:text)).to include("1h", "R$ 80,00")
    end

    it "shows the description of a service that has one" do
      create(:service, tenant: tenant, name: "Corte feminino", description: "Inclui lavagem e finalização.")
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Inclui lavagem e finalização.")
    end

    it "leaves no description line behind for a service without one" do
      create(:service, tenant: tenant, name: "Corte feminino", description: "Inclui lavagem e finalização.")
      create(:service, tenant: tenant, name: "Barba", description: nil)
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Barba")
      expect(response.body.scan("data-description").size).to eq(1)
    end

    it "marks a service that is disabled" do
      create(:service, tenant: tenant, name: "Barba", active: false)
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Barba")
      expect(response.body).to include(Views::Owner::Services::Index::DISABLED_LABEL)
    end

    it "leaves an active service unmarked" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).not_to include(Views::Owner::Services::Index::DISABLED_LABEL)
    end

    it "invites the first registration when there is no service yet" do
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include(Views::Owner::Services::Index::EMPTY_TITLE)
      expect(response.body).to include(Views::Owner::Services::Index::EMPTY_BODY)
      expect(response.body).not_to include("data-catalog")
    end

    it "drops the invitation once the catalog has a service" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).to include("data-catalog")
      expect(response.body).not_to include(Views::Owner::Services::Index::EMPTY_TITLE)
    end

    it "offers the registration from the heading once the catalog has a service" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include(%(<a href="#{new_owner_service_path}" class="#{Views::Owner::Services::Index::ACTION_CLASS}">#{Views::Owner::Services::Index::NEW_LABEL}</a>))
      expect(response.body.scan(%(href="#{new_owner_service_path}")).size).to eq(1)
      expect(response.body).not_to include(Views::Owner::Services::Index::FIRST_LABEL)
    end

    it "offers the registration inside the empty state alone when there is no service yet" do
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include(%(<a href="#{new_owner_service_path}" class="#{Views::Owner::Services::Index::ACTION_CLASS}">#{Views::Owner::Services::Index::FIRST_LABEL}</a>))
      expect(response.body.scan(%(href="#{new_owner_service_path}")).size).to eq(1)
      expect(response.body).not_to include(Views::Owner::Services::Index::NEW_LABEL)
    end

    it "opens the edit form from the name of every service" do
      beard_trim = create(:service, tenant: tenant, name: "Barba")
      haircut = create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include(%(<a href="#{edit_owner_service_path(beard_trim)}" class="#{Components::Service::Card::NAME_CLASS}">Barba</a>))
      expect(response.body).to include(%(<a href="#{edit_owner_service_path(haircut)}" class="#{Components::Service::Card::NAME_CLASS}">Corte feminino</a>))
    end

    it "sends an anonymous visitor to the login" do
      create(:service, tenant: tenant, name: "Corte feminino")
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_services_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "names no service on the login an anonymous visitor lands on" do
      create(:service, tenant: tenant, name: "Corte feminino")
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_services_path
      follow_redirect!

      expect(response.body).to include(%(action="#{owner_session_path}"))
      expect(response.body).not_to include("Corte feminino")
    end

    it "lists the services of the establishment in the host and none of another one" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      create(:service, tenant: other_tenant, name: "Barba do Zé")
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Corte feminino")
      expect(response.body).not_to include("Barba do Zé")
    end

    it "shows the price of the establishment in the host and not the sob consulta service of another one" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:service, tenant: other_tenant, name: "Avaliação do Zé", price_cents: nil)
      create(:service, tenant: tenant, name: "Coloração", price_cents: 9_000)
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("R$ 90,00")
      expect(response.body).not_to include("Avaliação do Zé")
      expect(response.body).not_to include(Service::Price::UNPRICED_LABEL)
    end

    it "shows the price of a hidden-price service with a badge saying the client does not see it" do
      create(:service, :price_hidden, tenant: tenant, name: "Primeira sessão", price_cents: 9_000)
      sign_in_owner(owner)

      get owner_services_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-catalog] span").map(&:text)).to include("R$ 90,00")
      expect(response.body).to include(Views::Owner::Services::Index::HIDDEN_PRICE_LABEL)
    end

    it "leaves a visible-price service without the hidden-price badge" do
      create(:service, tenant: tenant, name: "Corte feminino", price_cents: 9_000)
      sign_in_owner(owner)

      get owner_services_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-catalog] span").map(&:text)).to include("R$ 90,00")
      expect(response.body).not_to include(Views::Owner::Services::Index::HIDDEN_PRICE_LABEL)
    end

    it "leaves a service without a price free of the hidden-price badge even when hidden" do
      create(:service, :price_hidden, tenant: tenant, name: "Avaliação", price_cents: nil)
      sign_in_owner(owner)

      get owner_services_path

      expect(response.body).to include("Avaliação")
      expect(response.body).not_to include(Views::Owner::Services::Index::HIDDEN_PRICE_LABEL)
    end

    it "asks the database the same number of times for many services as for one" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)
      get owner_services_path
      single = count_queries { get owner_services_path }
      create_list(:service, 4, tenant: tenant)

      many = count_queries { get owner_services_path }

      expect(single).to be_positive
      expect(many).to eq(single)
    end
  end

  describe "GET /owner/services/new" do
    it "opens an empty registration form in the owner form card, with settings as the current section" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<h1 id="#{Components::Owner::FormCard::HEADING_ID}" class="#{Components::Owner::FormCard::TITLE_CLASS}">#{Views::Owner::Services::Form::NEW_TITLE}</h1>))
      expect(response.body).to include(%(action="#{owner_services_path}"))
      expect(response.body).to include(%(<a href="#{owner_settings_path}" aria-current="page"))
      expect(response.body).to include(Views::Owner::Services::Form::CREATE_LABEL)
      expect(document.at_css("[data-field='price'] input")["value"]).to be_nil
    end

    it "requires the name and the duration but not the price or the description" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-field='name'] input")["required"]).not_to be_nil
      expect(document.at_css("[data-field='duration_minutes'] input")["required"]).not_to be_nil
      expect(document.at_css("[data-field='price'] input")["required"]).to be_nil
      expect(document.at_css("[data-field='description'] textarea")["required"]).to be_nil
      expect(document.at_css("[data-field='description'] input")).to be_nil
    end

    it "caps the name and the description at the lengths the model accepts" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-field='name'] input")["maxlength"]).to eq(Service::NAME_MAX_LENGTH.to_s)
      expect(document.at_css("[data-field='description'] textarea")["maxlength"]).to eq(Service::DESCRIPTION_MAX_LENGTH.to_s)
    end

    it "bounds the duration with the rule of the model and ties it to the hint that states it" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-field='duration_minutes'] input")["type"]).to eq("number")
      expect(document.at_css("[data-field='duration_minutes'] input")["min"]).to eq(Service::MIN_DURATION_MINUTES.to_s)
      expect(document.at_css("[data-field='duration_minutes'] input")["max"]).to eq(Service::MAX_DURATION_MINUTES.to_s)
      expect(document.at_css("[data-field='duration_minutes'] input")["step"]).to eq(Service::DURATION_STEP_MINUTES.to_s)
      expect(document.at_css("[data-field='duration_minutes'] input")["aria-describedby"]).to eq(Views::Owner::Services::Form::DURATION_HINT_ID)
      expect(document.at_css("[data-field='duration_minutes']").at_css("##{Views::Owner::Services::Form::DURATION_HINT_ID}").text).to eq("Múltiplos de 5 minutos, até 8 horas.")
    end

    it "opens a decimal keyboard for the price and ties it to the hint that shows the format" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-field='price'] input")["type"]).to eq("text")
      expect(document.at_css("[data-field='price'] input")["inputmode"]).to eq("decimal")
      expect(document.at_css("[data-field='price'] input")["aria-describedby"]).to eq(Views::Owner::Services::Form::PRICE_HINT_ID)
      expect(document.at_css("[data-field='price']").at_css("##{Views::Owner::Services::Form::PRICE_HINT_ID}").text).to eq(Views::Owner::Services::Form::PRICE_HINT)
    end

    it "tells the owner a blank price shows to the client as sob consulta" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-field='price']").at_css("##{Views::Owner::Services::Form::PRICE_HINT_ID}").text).to include("sob consulta")
    end

    it "sends an anonymous visitor to the login" do
      host! "#{tenant.subdomain}.zubio.com.br"

      get new_owner_service_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "offers the show-price toggle checked on a new service" do
      sign_in_owner(owner)

      get new_owner_service_path

      document = Nokogiri::HTML5(response.body)
      toggle = document.at_css("[data-field='show_price']").at_css(%(input[type="checkbox"]))
      expect(toggle["name"]).to eq("service[show_price]")
      expect(toggle["checked"]).not_to be_nil
    end
  end

  describe "POST /owner/services" do
    it "creates the service in the establishment of the host" do
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields.merge(description: "Inclui lavagem e finalização.") } }.to change { ActsAsTenant.without_tenant { Service.count } }.by(1)

      service = ActsAsTenant.with_tenant(tenant) { Service.find_by!(name: "Corte feminino") }
      expect(response).to redirect_to(owner_services_path)
      expect([ service.duration_minutes, service.price_cents, service.description ]).to eq([ 45, 9_000, "Inclui lavagem e finalização." ])
    end

    it "lists a created service back on the catalog with a notice" do
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields }
      follow_redirect!

      expect(response.body).to include("Corte feminino")
      expect(response.body).to include("R$ 90,00")
      expect(response.body).to include("Serviço cadastrado.")
    end

    it "creates a service without a price" do
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields.merge(name: "Consulta de visagismo", price: "") }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.find_by!(name: "Consulta de visagismo").price_cents).to be_nil }
    end

    it "shows a created service without a price as sob consulta on the catalog" do
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields.merge(name: "Consulta de visagismo", price: "") }
      follow_redirect!

      expect(response.body).to include("Consulta de visagismo")
      expect(response.body).to include(Service::Price::UNPRICED_LABEL)
    end

    it "accepts a service without a description and stores none" do
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields.merge(description: "") }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.find_by!(name: "Corte feminino").description).to be_nil }
    end

    it "refuses a duration off the five-minute steps and gives the form back with what was typed, the error beside the duration" do
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields.merge(duration_minutes: "7") } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-field='name'] input")["value"]).to eq("Corte feminino")
      expect(document.at_css("[data-field='duration_minutes'] input")["value"]).to eq("7")
      expect(document.at_css("[data-field='price'] input")["value"]).to eq("90,00")
      expect(document.at_css("[data-field='duration_minutes']").text).to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
      expect(document.at_css("[data-field='name']").text).not_to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
    end

    it "states the refusal in the danger tone on the same screen" do
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields.merge(duration_minutes: "7") }

      expect(response.body).to include(Owner::ServicesController::REFUSED)
      expect(response.body).to include(%(class="#{Components::Alert::FRAME_CLASS} border-danger"))
      expect(response.body).not_to include("border-success")
    end

    it "refuses a duration with a fraction sent straight to the server" do
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields.merge(duration_minutes: "45.5") } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-field='duration_minutes']").text).to include(Service::DURATION_NOT_WHOLE_MESSAGE)
    end

    it "refuses a name the establishment already uses, with the error beside the name" do
      create(:service, tenant: tenant, name: "Corte feminino")
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-field='name']").text).to include(Service::NAME_TAKEN_MESSAGE)
      expect(document.at_css("[data-field='duration_minutes']").text).not_to include(Service::NAME_TAKEN_MESSAGE)
    end

    it "accepts a name another establishment already uses" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:service, tenant: other_tenant, name: "Corte feminino")
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.pluck(:name)).to eq([ "Corte feminino" ]) }
    end

    it "refuses a price it cannot read instead of storing it as zero" do
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields.merge(price: "noventa") } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-field='price'] input")["value"]).to eq("noventa")
      expect(document.at_css("[data-field='price']").text).to include(Service::PRICE_UNREADABLE_MESSAGE)
    end

    it "answers a price above what the column holds with the form instead of a server error" do
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields.merge(price: "30.000.000,00") } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-field='price']").text).to include(Service::PRICE_OUT_OF_RANGE_MESSAGE)
    end

    it "answers a name longer than the index holds with the form instead of a server error" do
      sign_in_owner(owner)

      expect { post owner_services_path, params: { service: service_fields.merge(name: "a" * 3_000) } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-field='name']").text).to include(Service::NAME_TOO_LONG_MESSAGE)
    end

    it "creates the service in the establishment of the host even when the body names another one" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      sign_in_owner(owner)

      post owner_services_path, params: { service: service_fields.merge(tenant_id: other_tenant.id) }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(Service.pluck(:name)).to eq([ "Corte feminino" ]) }
      ActsAsTenant.with_tenant(other_tenant) { expect(Service.count).to eq(0) }
    end

    it "sends an anonymous visitor to the login without creating anything" do
      host! "#{tenant.subdomain}.zubio.com.br"

      expect { post owner_services_path, params: { service: service_fields } }.not_to change { ActsAsTenant.without_tenant { Service.count } }

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "GET /owner/services/:id/edit" do
    it "opens the form filled with what the service stores" do
      service = create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      sign_in_owner(owner)

      get edit_owner_service_path(service)

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{owner_service_path(service)}"))
      expect(response.body).to include(Views::Owner::Services::Form::EDIT_TITLE)
      expect(response.body).to include(Views::Owner::Services::Form::UPDATE_LABEL)
      expect(document.at_css("[data-field='name'] input")["value"]).to eq("Corte feminino")
      expect(document.at_css("[data-field='duration_minutes'] input")["value"]).to eq("45")
      expect(document.at_css("[data-field='price'] input")["value"]).to eq("90,00")
    end

    it "opens the form for a disabled service too" do
      service = create(:service, tenant: tenant, name: "Barba", active: false)
      sign_in_owner(owner)

      get edit_owner_service_path(service)

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(document.at_css("[data-field='name'] input")["value"]).to eq("Barba")
    end

    it "answers not found for the service of another establishment, with none of its data" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      other_service = create(:service, tenant: other_tenant, name: "Barba do Zé", description: "Navalha e toalha quente.")
      sign_in_owner(owner)
      allow(Rails.application).to receive(:env_config).and_wrap_original do |env_config|
        env_config.call.merge("action_dispatch.show_detailed_exceptions" => false)
      end

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
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(price: "100,00") }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.price_cents).to eq(10_000) }
    end

    it "shows the changed price on the catalog with a notice" do
      service = create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(price: "100,00") }
      follow_redirect!

      expect(response.body).to include("Serviço atualizado.")
      expect(response.body).to include("R$ 100,00")
    end

    it "clears the price when the owner erases it" do
      service = create(:service, tenant: tenant, name: "Corte", price_cents: 4_500)
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(name: "Corte", price: "") }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.price_cents).to be_nil }
    end

    it "shows a service whose price was erased as sob consulta on the catalog" do
      service = create(:service, tenant: tenant, name: "Corte", price_cents: 4_500)
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(name: "Corte", price: "") }
      follow_redirect!

      expect(response.body).to include(Service::Price::UNPRICED_LABEL)
    end

    it "keeps the stored duration when the new one is out of range, with the error beside the duration" do
      service = create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45, price_cents: 9_000)
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(duration_minutes: "600") }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.duration_minutes).to eq(45) }
      expect(document.at_css("[data-field='duration_minutes'] input")["value"]).to eq("600")
      expect(document.at_css("[data-field='duration_minutes']").text).to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
      expect(document.at_css("[data-field='price']").text).not_to include(Service::DURATION_OUT_OF_STEP_MESSAGE)
      expect(response.body).to include(Owner::ServicesController::REFUSED)
    end

    it "leaves the service of another establishment untouched and answers not found" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      other_service = create(:service, tenant: other_tenant, name: "Barba do Zé", price_cents: 5_000)
      sign_in_owner(owner)

      patch owner_service_path(other_service), params: { service: service_fields.merge(name: "Hijacked", price: "1,00") }

      expect(response).to have_http_status(:not_found)
      ActsAsTenant.with_tenant(other_tenant) do
        expect(other_service.reload.name).to eq("Barba do Zé")
        expect(other_service.price_cents).to eq(5_000)
      end
    end

    it "turns the price off when the owner unchecks the toggle" do
      service = create(:service, tenant: tenant, name: "Primeira sessão", price_cents: 9_000)
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(name: "Primeira sessão", show_price: "0") }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.show_price).to be(false) }
    end

    it "keeps the price on when the toggle comes back checked" do
      service = create(:service, :price_hidden, tenant: tenant, name: "Primeira sessão", price_cents: 9_000)
      sign_in_owner(owner)

      patch owner_service_path(service), params: { service: service_fields.merge(name: "Primeira sessão", show_price: "1") }

      expect(response).to redirect_to(owner_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.show_price).to be(true) }
    end

    it "sends an anonymous visitor to the login without changing the service" do
      service = create(:service, tenant: tenant, name: "Corte feminino", price_cents: 9_000)
      host! "#{tenant.subdomain}.zubio.com.br"

      patch owner_service_path(service), params: { service: service_fields.merge(price: "1,00") }

      expect(response).to redirect_to(new_owner_session_path)
      ActsAsTenant.with_tenant(tenant) { expect(service.reload.price_cents).to eq(9_000) }
    end
  end
end
