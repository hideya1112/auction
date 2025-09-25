class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :auction, null: false, foreign_key: true
      t.text :message
      t.string :notification_type
      t.boolean :read

      t.timestamps
    end
  end
end
