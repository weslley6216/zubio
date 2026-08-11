class CreateBrandings < ActiveRecord::Migration[8.1]
  def change
    create_table :brandings do |t|
      t.references :tenant, null: false, foreign_key: true, index: { unique: true }
      t.string :brand_600, null: false

      t.timestamps
    end
  end
end
