class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :user_id, null: false
      t.string :name, null: false

      t.timestamps
    end
    
    add_index :users, :user_id, unique: true
    add_index :users, :name
  end
end
