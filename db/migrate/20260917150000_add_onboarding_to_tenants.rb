class AddOnboardingToTenants < ActiveRecord::Migration[8.1]
  def up
    add_column :tenants, :onboarding_step, :integer, null: false, default: 0
    change_column_null :tenants, :name, true
  end

  def down
    change_column_null :tenants, :name, false
    remove_column :tenants, :onboarding_step
  end
end
