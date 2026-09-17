class CreateWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :working_hours do |t|
      t.integer :weekday, null: false, limit: 2
      t.time :opens_at, null: false
      t.time :closes_at, null: false
      t.references :professional, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.timestamps
    end
    add_index :working_hours, [ :tenant_id, :professional_id, :weekday ]
  end
end
