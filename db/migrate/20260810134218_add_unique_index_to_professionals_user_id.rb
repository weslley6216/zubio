class AddUniqueIndexToProfessionalsUserId < ActiveRecord::Migration[8.1]
  def change
    remove_index :professionals, :user_id
    add_index :professionals, :user_id, unique: true
  end
end
