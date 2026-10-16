class AddCancelTokenToAppointments < ActiveRecord::Migration[8.1]
  def up
    add_column :appointments, :cancel_token, :string
    add_index :appointments, :cancel_token, unique: true
    backfill_tokens
    change_column_null :appointments, :cancel_token, false
  end

  def down
    remove_column :appointments, :cancel_token
  end

  private

  def backfill_tokens
    ActsAsTenant.without_tenant do
      Appointment.where(cancel_token: nil).find_each do |appointment|
        appointment.update_columns(cancel_token: Appointment.generate_unique_secure_token(length: Appointment::MINIMUM_TOKEN_LENGTH))
      end
    end
  end
end
