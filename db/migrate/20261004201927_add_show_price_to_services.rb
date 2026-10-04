class AddShowPriceToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :show_price, :boolean, null: false, default: true
  end
end
