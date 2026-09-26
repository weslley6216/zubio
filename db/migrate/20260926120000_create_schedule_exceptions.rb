class CreateScheduleExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_exceptions do |t|
      t.date :occurs_on, null: false
      t.boolean :closed, null: false, default: true
      t.time :opens_at
      t.time :closes_at
      t.string :reason
      t.references :professional, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.timestamps
    end
    add_index :schedule_exceptions, [ :tenant_id, :professional_id, :occurs_on ], unique: true
  end
end
