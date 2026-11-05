class AddBrandBackgroundToBrandings < ActiveRecord::Migration[8.1]
  def change
    add_column :brandings, :brand_background, :string
  end
end
