class CreateProfessionals < ActiveRecord::Migration[8.1]
  def change
    create_table :professionals do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :display_name, null: false
      t.text :bio
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
