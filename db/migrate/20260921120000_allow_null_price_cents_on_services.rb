class AllowNullPriceCentsOnServices < ActiveRecord::Migration[8.1]
  def up
    change_column_null :services, :price_cents, true
  end

  def down
    change_column_null :services, :price_cents, false
  end
end
