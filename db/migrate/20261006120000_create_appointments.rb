class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gist"

    create_table :appointments do |t|
      t.references :professional, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "confirmed"

      t.timestamps
    end

    add_index :appointments, [ :tenant_id, :professional_id, :starts_at ]

    add_check_constraint :appointments, "ends_at > starts_at", name: "appointments_positive_duration"

    add_exclusion_constraint :appointments,
      "professional_id WITH =, tsrange(starts_at, ends_at, '[)') WITH &&",
      using: :gist,
      where: "status <> 'cancelled'",
      name: "appointments_no_overlap"
  end
end
