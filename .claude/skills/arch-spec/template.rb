require "rails_helper"

RSpec.describe ChangeMe, type: :model do
  describe "validations" do
    it "requires a name" do
      change_me = build(:change_me, name: nil)

      expect(change_me).not_to be_valid
    end
  end

  describe "tenant isolation" do
    it "does not include records from another tenant" do
      other_tenant = create(:tenant)
      create(:change_me, tenant: other_tenant)
      own_change_me = create(:change_me, tenant: ActsAsTenant.current_tenant)

      expect(described_class.all).to contain_exactly(own_change_me)
    end
  end
end
