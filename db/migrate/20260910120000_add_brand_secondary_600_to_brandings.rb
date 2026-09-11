class AddBrandSecondary600ToBrandings < ActiveRecord::Migration[8.1]
  def change
    add_column :brandings, :brand_secondary_600, :string
  end
end
