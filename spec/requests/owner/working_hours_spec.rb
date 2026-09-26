require "rails_helper"

RSpec.describe "Owner working hours", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  def sign_in(establishment = tenant, user = owner)
    host! "#{establishment.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: user.email, password: "s3cr3t123" }
  end

  def professional_for(user, establishment = tenant)
    ActsAsTenant.with_tenant(establishment) { create(:professional, tenant: establishment, user: user) }
  end

  def saved_hours(professional, establishment = tenant)
    ActsAsTenant.with_tenant(establishment) { professional.reload.working_hours.ordered.to_a }
  end

  def document = Nokogiri::HTML5(response.body)

  def toggle(weekday) = document.at_css(%(input[name="working_hours[#{weekday}][active]"]))

  describe "GET /owner/working_hours/edit" do
    it "shows the saved days marked with their ranges and the rest unmarked" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in

      get edit_owner_working_hours_path

      expect(response).to have_http_status(:ok)
      expect(toggle(2)["checked"]).to be_truthy
      expect(document.at_css(%(input[name="working_hours[2][opens_at_0]"]))["value"]).to eq("09:00")
      expect(document.at_css(%(input[name="working_hours[2][closes_at_0]"]))["value"]).to eq("18:00")
      expect(toggle(3)["checked"]).to be_falsey
    end

    it "greets an owner without a schedule with a blank week and an invitation" do
      professional_for(owner)
      sign_in

      get edit_owner_working_hours_path

      expect(WorkingHour::WEEKDAYS.map { |weekday| toggle(weekday)["checked"] }).to all(be_falsey)
      expect(document.at_css("[data-invite]")).to be_present
    end

    it "drops the invitation once a day is declared" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in

      get edit_owner_working_hours_path

      expect(document.at_css("[data-invite]")).to be_nil
    end

    it "marks Configurações as the current section on this screen" do
      professional_for(owner)
      sign_in

      get edit_owner_working_hours_path

      expect(document.at_css("nav a[aria-current='page']").text).to eq(Components::Owner::Header::SETTINGS_LABEL)
    end

    it "names every time field and flags the second range as optional" do
      professional_for(owner)
      sign_in

      get edit_owner_working_hours_path

      labels = document.css("[data-day='2'] input[type='time']").map { |field| field["aria-label"] }
      expect(labels).to eq(%w[Abre Fecha Abre Fecha])
      expect(document.at_css("[data-day='2']").text).to include(Views::Owner::WorkingHours::Edit::SECOND_RANGE_HINT)
    end

    it "paints the day chips with brand tokens, never the landing demo tokens" do
      professional_for(owner)
      sign_in

      get edit_owner_working_hours_path

      expect(response.body).not_to include("demo-")
    end

    it "sends an anonymous visitor to the login with no hours in the response" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get edit_owner_working_hours_path

      expect(response).to redirect_to(new_owner_session_path)
      expect(response.body).not_to include("09:00")
    end

    it "loads the week in the same number of queries with one day or seven" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in
      one_day = count_queries { get edit_owner_working_hours_path }

      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!((0..6).index_with { [ [ "09:00", "18:00" ] ] }) }

      expect(count_queries { get edit_owner_working_hours_path }).to eq(one_day)
    end
  end

  describe "PATCH /owner/working_hours" do
    it "stores the declared day on the owner's professional" do
      professional = professional_for(owner)
      sign_in

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "18:00" } } }

      ranges = saved_hours(professional).map { |working_hour| [ working_hour.weekday, working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] }
      expect(response).to redirect_to(edit_owner_working_hours_path)
      expect(ranges).to eq([ [ 2, "09:00", "18:00" ] ])
    end

    it "stores two ranges for a day with a midday break" do
      professional = professional_for(owner)
      sign_in

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "12:00", opens_at_1: "14:00", closes_at_1: "18:00" } } }

      expect(saved_hours(professional).size).to eq(2)
    end

    it "removes only the unchecked day" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ], 3 => [ [ "09:00", "18:00" ] ]) }
      sign_in

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "18:00" } } }

      expect(saved_hours(professional).map(&:weekday)).to eq([ 2 ])
    end

    it "refuses an inverted range, flags the day and keeps the saved day intact" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "18:00" }, "3" => { active: "1", opens_at_0: "18:00", closes_at_0: "09:00" } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-day='3'] .text-danger").text).to eq("o fechamento precisa ser depois da abertura")
      expect(saved_hours(professional).map(&:weekday)).to eq([ 2 ])
    end

    it "refuses overlapping ranges on the same day and writes nothing" do
      professional = professional_for(owner)
      sign_in

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "12:00", opens_at_1: "11:00", closes_at_1: "15:00" } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(WeeklySchedule::OVERLAP_MESSAGE)
      expect(saved_hours(professional)).to be_empty
    end
  end

  describe "tenant isolation" do
    it "shows the host's schedule and none of another tenant's, and saving here leaves the other intact" do
      professional = professional_for(owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      aurora_owner = create(:user, tenant: aurora, email: "ana@example.com", password: "s3cr3t123")
      aurora_professional = professional_for(aurora_owner, aurora)
      ActsAsTenant.with_tenant(aurora) { aurora_professional.replace_working_hours!(5 => [ [ "08:00", "13:00" ] ]) }
      sign_in

      get edit_owner_working_hours_path
      expect(toggle(2)["checked"]).to be_truthy
      expect(toggle(5)["checked"]).to be_falsey

      patch owner_working_hours_path, params: { working_hours: { "4" => { active: "1", opens_at_0: "10:00", closes_at_0: "16:00" } } }

      expect(saved_hours(aurora_professional, aurora).map(&:weekday)).to eq([ 5 ])
    end
  end
end
