class AddHandoffGenerationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :handoff_generation, :integer, default: 0, null: false
  end
end
