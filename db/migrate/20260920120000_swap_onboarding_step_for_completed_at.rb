class SwapOnboardingStepForCompletedAt < ActiveRecord::Migration[8.1]
  def up
    add_column :tenants, :onboarding_completed_at, :datetime
    remove_column :tenants, :onboarding_step
  end

  def down
    add_column :tenants, :onboarding_step, :integer, null: false, default: 0
    remove_column :tenants, :onboarding_completed_at
  end
end
