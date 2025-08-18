class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.text :description
      t.integer :starting_price, null: false
      t.string :image_url

      t.timestamps
    end
    
    add_index :items, :name
  end
end
