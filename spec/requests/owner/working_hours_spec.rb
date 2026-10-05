require "rails_helper"

RSpec.describe "Owner working hours", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  describe "GET /owner/working_hours/edit" do
    it "shows the saved days marked with their ranges and the rest unmarked" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(document.at_css(%(input[name="working_hours[2][active]"]))["checked"]).to be_truthy
      expect(document.at_css(%(input[name="working_hours[2][opens_at_0]"]))["value"]).to eq("09:00")
      expect(document.at_css(%(input[name="working_hours[2][closes_at_0]"]))["value"]).to eq("18:00")
      expect(document.at_css(%(input[name="working_hours[3][active]"]))["checked"]).to be_falsey
    end

    it "greets an owner without a schedule with a blank week and an invitation" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      document = Nokogiri::HTML5(response.body)
      expect(WorkingHour::WEEKDAYS.map { |weekday| document.at_css(%(input[name="working_hours[#{weekday}][active]"]))["checked"] }).to all(be_falsey)
      expect(document.at_css("[data-invite]")).to be_present
    end

    it "drops the invitation once a day is declared" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-invite]")).to be_nil
    end

    it "marks Configurações as the current section on this screen" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("nav a[aria-current='page']").text).to eq(Components::Owner::Header::SETTINGS_LABEL)
    end

    it "names every time field and flags the second range as optional" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      document = Nokogiri::HTML5(response.body)
      labels = document.css("[data-day='2'] input[type='time']").map { |field| field["aria-label"] }
      expect(labels).to eq(%w[Abre Fecha Abre Fecha])
      expect(document.at_css("[data-day='2']").text).to include(Views::Owner::WorkingHours::Edit::SECOND_RANGE_HINT)
    end

    it "paints the day chips with brand tokens, never the landing demo tokens" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      expect(response.body).not_to include("demo-")
    end

    it "sends an anonymous visitor to the login with no hours in the response" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get edit_owner_working_hours_path

      expect(response).to redirect_to(new_owner_session_path)
      expect(response.body).not_to include("09:00")
    end

    it "loads the week in the same number of queries with one day or seven" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in_owner(owner)
      one_day = count_queries { get edit_owner_working_hours_path }
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!((0..6).index_with { [ [ "09:00", "18:00" ] ] }) }

      seven_days = count_queries { get edit_owner_working_hours_path }

      expect(seven_days).to eq(one_day)
    end
  end

  describe "PATCH /owner/working_hours" do
    it "stores the declared day on the owner's professional" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "18:00" } } }

      ranges = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }.map { |working_hour| [ working_hour.weekday, working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] }
      expect(response).to redirect_to(edit_owner_working_hours_path)
      expect(ranges).to eq([ [ 2, "09:00", "18:00" ] ])
    end

    it "stores two ranges for a day with a midday break" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "12:00", opens_at_1: "14:00", closes_at_1: "18:00" } } }

      expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.count }).to eq(2)
    end

    it "removes only the unchecked day" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ], 3 => [ [ "09:00", "18:00" ] ]) }
      sign_in_owner(owner)

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "18:00" } } }

      expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }).to eq([ 2 ])
    end

    it "refuses an inverted range, flags the day and keeps the saved day intact" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      sign_in_owner(owner)

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "18:00" }, "3" => { active: "1", opens_at_0: "18:00", closes_at_0: "09:00" } } }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(document.at_css("[data-day='3'] .text-danger").text).to eq("o fechamento precisa ser depois da abertura")
      expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }).to eq([ 2 ])
    end

    it "refuses overlapping ranges on the same day and writes nothing" do
      professional = create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      patch owner_working_hours_path, params: { working_hours: { "2" => { active: "1", opens_at_0: "09:00", closes_at_0: "12:00", opens_at_1: "11:00", closes_at_1: "15:00" } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(WeeklySchedule::OVERLAP_MESSAGE)
      expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.to_a }).to be_empty
    end
  end

  describe "tenant isolation" do
    it "shows the host's schedule and none of another tenant's" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      ActsAsTenant.with_tenant(aurora) { aurora_professional.replace_working_hours!(5 => [ [ "08:00", "13:00" ] ]) }
      sign_in_owner(owner)

      get edit_owner_working_hours_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css(%(input[name="working_hours[2][active]"]))["checked"]).to be_truthy
      expect(document.at_css(%(input[name="working_hours[5][active]"]))["checked"]).to be_falsey
    end

    it "saves the host's schedule and leaves another tenant's intact" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      ActsAsTenant.with_tenant(aurora) { aurora_professional.replace_working_hours!(5 => [ [ "08:00", "13:00" ] ]) }
      sign_in_owner(owner)

      patch owner_working_hours_path, params: { working_hours: { "4" => { active: "1", opens_at_0: "10:00", closes_at_0: "16:00" } } }

      expect(response).to redirect_to(edit_owner_working_hours_path)
      expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }).to eq([ 4 ])
      expect(ActsAsTenant.with_tenant(aurora) { aurora_professional.working_hours.ordered.map(&:weekday) }).to eq([ 5 ])
    end
  end
end
