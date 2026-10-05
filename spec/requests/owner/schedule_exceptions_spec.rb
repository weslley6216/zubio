require "rails_helper"

RSpec.describe "Owner schedule exceptions", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  describe "GET /owner/schedule_exceptions" do
    it "lists an upcoming closure with its date and a closed badge" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(document.css("[data-exception]").size).to eq(1)
      expect(document.css("[data-exception]").first.text).to include(Date.current.next_week(:monday).strftime("%d"))
      expect(document.css("[data-exception]").first.text).to include(Views::Owner::ScheduleExceptions::Index::CLOSED_LABEL)
    end

    it "shows the window for an open day and no window for a full closure" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      windows = document.css("[data-exception]").map { |row| row.at_css("[data-window]")&.text }
      expect(windows).to include("09:00 às 12:00")
      expect(windows).to include(nil)
    end

    it "prints the reason when present and leaves no empty slot when absent" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday), reason: "Feriado")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday), reason: nil)
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      reasons = document.css("[data-exception]").map { |row| row.at_css("[data-reason]")&.text }
      expect(reasons).to include("Feriado")
      expect(reasons).to include(nil)
    end

    it "heads the upcoming list with its section label" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-exceptions]").text).to include(Views::Owner::ScheduleExceptions::Index::UPCOMING_LABEL)
    end

    it "leaves no detail slot on a closure without a reason" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday), reason: nil)
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-exception]").first.css("[data-detail] > *").size).to eq(1)
    end

    it "hides a past exception and keeps the upcoming one" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current - 1)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-exception]").size).to eq(1)
      expect(document.css("[data-exception]").first.text).to include(Date.current.next_week(:monday).strftime("%d"))
    end

    it "invites the first registration when nothing is upcoming, with no empty list" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-empty]")).to be_present
      expect(document.at_css("[data-exceptions]")).to be_nil
      expect(document.at_css(%(form[action="#{owner_schedule_exceptions_path}"]))).to be_present
    end

    it "starts the attendance toggle off so a new exception is a full closure by default" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css(%(input[name="schedule_exception[attends]"]))["checked"]).to be_falsey
    end

    it "marks Configurações as the current section" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("nav a[aria-current='page']").text).to eq(Components::Owner::Header::SETTINGS_LABEL)
    end

    it "sends an anonymous visitor to the login with no date in the response" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_schedule_exceptions_path

      expect(response).to redirect_to(new_owner_session_path)
      expect(response.body).not_to include(Date.current.next_week(:monday).strftime("%d"))
    end

    it "paints the reduced badge with brand tokens and the closed badge muted, never the landing demo tokens" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      expect(response.body).to include("bg-brand-soft")
      expect(response.body).to include("bg-surface-3")
      expect(response.body).not_to include("demo-")
    end

    it "lists many exceptions in the same number of queries as one" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      sign_in_owner(owner)
      one = count_queries { get owner_schedule_exceptions_path }
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:wednesday))

      three = count_queries { get owner_schedule_exceptions_path }

      expect(three).to eq(one)
    end
  end

  describe "POST /owner/schedule_exceptions" do
    it "stores a full-day closure on the owner's professional" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:monday).iso8601 } }

      stored = ActsAsTenant.with_tenant(tenant) { professional.schedule_exceptions.sole }
      expect(response).to redirect_to(owner_schedule_exceptions_path)
      expect(stored).to be_closed
      expect(stored.opens_at).to be_nil
    end

    it "stores an alternate window when the owner says they attend" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:saturday).iso8601, attends: "1", opens_at: "09:00", closes_at: "12:00" } }

      stored = ActsAsTenant.with_tenant(tenant) { professional.schedule_exceptions.sole }
      expect(stored).not_to be_closed
      expect(stored.opens_at.strftime("%H:%M")).to eq("09:00")
      expect(stored.closes_at.strftime("%H:%M")).to eq("12:00")
    end

    it "discards a submitted window when the owner does not say they attend" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:monday).iso8601, opens_at: "09:00", closes_at: "12:00" } }

      stored = ActsAsTenant.with_tenant(tenant) { professional.schedule_exceptions.sole }
      expect(stored).to be_closed
      expect(stored.opens_at).to be_nil
      expect(stored.closes_at).to be_nil
    end

    it "refuses a date already registered, flags the date and keeps a single entry" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      sign_in_owner(owner)

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:monday).iso8601 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Nokogiri::HTML5(response.body).at_css("#schedule_exception_occurs_on").parent.at_css(".text-danger")).to be_present
      expect(ActsAsTenant.with_tenant(tenant) { professional.schedule_exceptions.count }).to eq(1)
    end

    it "refuses an attended day with no window, flags the window and writes nothing" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:saturday).iso8601, attends: "1" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("informe o horário de atendimento")
      expect(ActsAsTenant.with_tenant(tenant) { professional.schedule_exceptions.count }).to eq(0)
    end
  end

  describe "DELETE /owner/schedule_exceptions/:id" do
    it "removes the owner's exception and drops it from the list" do
      professional = create(:professional, tenant: tenant, user: owner)
      exception = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      sign_in_owner(owner)

      delete owner_schedule_exception_path(exception)

      expect(response).to redirect_to(owner_schedule_exceptions_path)
      expect(ActsAsTenant.with_tenant(tenant) { ScheduleException.exists?(exception.id) }).to be(false)
    end
  end

  describe "tenant isolation" do
    it "lists only the host's exception" do
      professional = create(:professional, tenant: tenant, user: owner)
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:schedule_exception, tenant: aurora, professional: create(:professional, tenant: aurora), occurs_on: Date.current.next_week(:tuesday))
      sign_in_owner(owner)

      get owner_schedule_exceptions_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-exception]").size).to eq(1)
      expect(document.at_css("[data-exception]").text).to include(Date.current.next_week(:monday).strftime("%d"))
    end

    it "never removes another tenant's exception" do
      professional = create(:professional, tenant: tenant, user: owner)
      own = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      foreign = create(:schedule_exception, tenant: aurora, professional: create(:professional, tenant: aurora), occurs_on: Date.current.next_week(:tuesday))
      sign_in_owner(owner)

      delete owner_schedule_exception_path(foreign)

      expect(ActsAsTenant.with_tenant(aurora) { ScheduleException.exists?(foreign.id) }).to be(true)
      expect(ActsAsTenant.with_tenant(tenant) { ScheduleException.exists?(own.id) }).to be(true)
    end
  end
end
