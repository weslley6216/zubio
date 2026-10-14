class AddPasswordResetGenerationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_reset_generation, :integer, default: 0, null: false
  end
end
