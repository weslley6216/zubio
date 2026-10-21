class AddClaimedAtToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_column :appointments, :claimed_at, :datetime
  end
end
