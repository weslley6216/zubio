require "rails_helper"

RSpec.describe Session, type: :model do
  let(:tenant) { create(:tenant) }

  it "belongs to the current tenant when created inside its scope" do
    user = create(:user, tenant: tenant)

    session = ActsAsTenant.with_tenant(tenant) { user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1") }

    expect(session.tenant).to eq(tenant)
  end

  it "belongs to a user" do
    user = create(:user, tenant: tenant)

    session = create(:session, tenant: tenant, user: user)

    expect(session.user).to eq(user)
  end

  it "does not find another tenant's session in the current scope" do
    other_tenant = create(:tenant, subdomain: "salon-b")
    other_session = create(:session, tenant: other_tenant)
    own_session = create(:session, tenant: tenant)

    found = ActsAsTenant.with_tenant(tenant) { Session.all.to_a }

    expect(found).to include(own_session)
    expect(found).not_to include(other_session)
  end
end
