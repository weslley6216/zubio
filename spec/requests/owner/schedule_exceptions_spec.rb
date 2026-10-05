require "rails_helper"

RSpec.describe "Owner schedule exceptions", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  def sign_in(establishment = tenant, user = owner)
    host! "#{establishment.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: user.email, password: "s3cr3t123" }
  end

  def professional_for(user, establishment = tenant)
    ActsAsTenant.with_tenant(establishment) { create(:professional, tenant: establishment, user: user) }
  end

  def document = Nokogiri::HTML5(response.body)

  def rows = document.css("[data-exception]")

  describe "GET /owner/schedule_exceptions" do
    it "lists an upcoming closure with its date and a closed badge" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday)) }
      sign_in

      get owner_schedule_exceptions_path

      expect(response).to have_http_status(:ok)
      expect(rows.size).to eq(1)
      expect(rows.first.text).to include(Date.current.next_week(:monday).strftime("%d"))
      expect(rows.first.text).to include(Views::Owner::ScheduleExceptions::Index::CLOSED_LABEL)
    end

    it "shows the window for an open day and no window for a full closure" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
        create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      end
      sign_in

      get owner_schedule_exceptions_path

      windows = rows.map { |row| row.at_css("[data-window]")&.text }
      expect(windows).to include("09:00 – 12:00")
      expect(windows).to include(nil)
    end

    it "prints the reason when present and leaves no empty slot when absent" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday), reason: "Feriado")
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday), reason: nil)
      end
      sign_in

      get owner_schedule_exceptions_path

      reasons = rows.map { |row| row.at_css("[data-reason]")&.text }
      expect(reasons).to include("Feriado")
      expect(reasons).to include(nil)
    end

    it "hides a past exception and keeps the upcoming one" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current - 1)
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      end
      sign_in

      get owner_schedule_exceptions_path

      expect(rows.size).to eq(1)
      expect(rows.first.text).to include(Date.current.next_week(:monday).strftime("%d"))
    end

    it "invites the first registration when nothing is upcoming, with no empty list" do
      professional_for(owner)
      sign_in

      get owner_schedule_exceptions_path

      expect(document.at_css("[data-empty]")).to be_present
      expect(document.at_css("[data-exceptions]")).to be_nil
      expect(document.at_css(%(form[action="#{owner_schedule_exceptions_path}"]))).to be_present
    end

    it "starts the attendance toggle off so a new exception is a full closure by default" do
      professional_for(owner)
      sign_in

      get owner_schedule_exceptions_path

      expect(document.at_css(%(input[name="schedule_exception[attends]"]))["checked"]).to be_falsey
    end

    it "marks Configurações as the current section" do
      professional_for(owner)
      sign_in

      get owner_schedule_exceptions_path

      expect(document.at_css("nav a[aria-current='page']").text).to eq(Components::Owner::Header::SETTINGS_LABEL)
    end

    it "sends an anonymous visitor to the login with no date in the response" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_schedule_exceptions_path

      expect(response).to redirect_to(new_owner_session_path)
      expect(response.body).not_to include(Date.current.next_week(:monday).strftime("%d"))
    end

    it "paints the reduced badge with brand tokens and the closed badge muted, never the landing demo tokens" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
        create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      end
      sign_in

      get owner_schedule_exceptions_path

      expect(response.body).to include("bg-brand-soft")
      expect(response.body).to include("bg-surface-3")
      expect(response.body).not_to include("demo-")
    end

    it "lists many exceptions in the same number of queries as one" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday)) }
      sign_in
      one = count_queries { get owner_schedule_exceptions_path }

      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:wednesday))
      end

      expect(count_queries { get owner_schedule_exceptions_path }).to eq(one)
    end
  end

  describe "POST /owner/schedule_exceptions" do
    def saved(professional, establishment = tenant)
      ActsAsTenant.with_tenant(establishment) { professional.reload.schedule_exceptions.order(:occurs_on).to_a }
    end

    it "stores a full-day closure on the owner's professional and shows it afterwards" do
      professional = professional_for(owner)
      sign_in

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:monday).iso8601 } }

      stored = saved(professional)
      expect(response).to redirect_to(owner_schedule_exceptions_path)
      expect(stored.size).to eq(1)
      expect(stored.first).to be_closed
      expect(stored.first.opens_at).to be_nil
    end

    it "stores an alternate window when the owner says they attend" do
      professional = professional_for(owner)
      sign_in

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:saturday).iso8601, attends: "1", opens_at: "09:00", closes_at: "12:00" } }

      stored = saved(professional).first
      expect(stored).not_to be_closed
      expect(stored.opens_at.strftime("%H:%M")).to eq("09:00")
      expect(stored.closes_at.strftime("%H:%M")).to eq("12:00")
    end

    it "refuses a date already registered, flags the date and keeps a single entry" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday)) }
      sign_in

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:monday).iso8601 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Nokogiri::HTML5(response.body).at_css("#schedule_exception_occurs_on").parent.at_css(".text-danger")).to be_present
      expect(saved(professional).size).to eq(1)
    end

    it "refuses an attended day with no window, flags the window and writes nothing" do
      professional = professional_for(owner)
      sign_in

      post owner_schedule_exceptions_path, params: { schedule_exception: { occurs_on: Date.current.next_week(:saturday).iso8601, attends: "1" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("informe o horário de atendimento")
      expect(saved(professional)).to be_empty
    end
  end
end
