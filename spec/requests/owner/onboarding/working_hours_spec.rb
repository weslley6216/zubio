require "rails_helper"

RSpec.describe "Owner onboarding working hours", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner, display_name: owner.name) }
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  def owner_professional(tenant, owner)
    ActsAsTenant.with_tenant(tenant) { Professional.find_by!(user_id: owner.id) }
  end

  describe "GET /owner/onboarding/working_hours" do
    it "shows the working hours question with the fifth-of-five counter" do
      tenant = create(:tenant, :at_working_hours, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_working_hours_path

      expect(response.body).to include("5 de 5")
    end

    it "redirects a tenant that has already finished onboarding to the dashboard" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_working_hours_path

      expect(response).to redirect_to(owner_dashboard_path)
    end
  end

  describe "PATCH /owner/onboarding/working_hours" do
    it "saves the schedule on the owner's professional and redirects to the final screen" do
      tenant = create(:tenant, :at_working_hours, subdomain: "barbearia-do-ze")
      owner = sign_in(tenant)

      patch owner_onboarding_working_hours_path, params: {
        working_hours: { weekdays: %w[2 3 4 5 6], opens_at: "09:00", closes_at: "18:00" }
      }

      expect(tenant.reload).to be_onboarding_done
      expect(response).to redirect_to(owner_onboarding_final_path)
      hours = ActsAsTenant.with_tenant(tenant) { owner_professional(tenant, owner).working_hours.to_a }
      expect(hours.size).to eq(5)
    end

    it "excludes the break from the saved schedule" do
      tenant = create(:tenant, :at_working_hours, subdomain: "barbearia-do-ze")
      owner = sign_in(tenant)

      patch owner_onboarding_working_hours_path, params: {
        working_hours: { weekdays: %w[2 3 4 5 6], opens_at: "09:00", closes_at: "18:00",
                          break_starts_at: "12:00", break_ends_at: "14:00" }
      }

      hours = ActsAsTenant.with_tenant(tenant) { owner_professional(tenant, owner).working_hours.to_a }
      covering_the_break = hours.any? { |hour| hour.opens_at.strftime("%H:%M") < "14:00" && "12:00" < hour.closes_at.strftime("%H:%M") }
      expect(hours.size).to eq(10)
      expect(covering_the_break).to be false
    end

    it "rejects an invalid range and stays on the step" do
      tenant = create(:tenant, :at_working_hours, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      patch owner_onboarding_working_hours_path, params: {
        working_hours: { weekdays: %w[2], opens_at: "18:00", closes_at: "09:00" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tenant.reload).to be_onboarding_working_hours
    end

    it "enqueues the completion email" do
      tenant = create(:tenant, :at_working_hours, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      expect {
        patch owner_onboarding_working_hours_path, params: {
          working_hours: { weekdays: %w[2], opens_at: "09:00", closes_at: "18:00" }
        }
      }.to have_enqueued_mail(OwnerMailer, :completed)
    end

    it "writes the schedule only to the target tenant" do
      tenant = create(:tenant, :at_working_hours, subdomain: "barbearia-do-ze")
      other_tenant = create(:tenant, :at_working_hours, subdomain: "other-onboarding")
      other_owner = create(:user, tenant: other_tenant, name: "José Silva", email: "jose@example.com", password: "s3cr3t123")
      ActsAsTenant.with_tenant(other_tenant) { create(:professional, tenant: other_tenant, user: other_owner) }
      sign_in(tenant)

      patch owner_onboarding_working_hours_path, params: {
        working_hours: { weekdays: %w[2], opens_at: "09:00", closes_at: "18:00" }
      }

      other_hours = ActsAsTenant.with_tenant(other_tenant) { owner_professional(other_tenant, other_owner).working_hours.to_a }
      expect(other_hours).to be_empty
    end
  end
end
