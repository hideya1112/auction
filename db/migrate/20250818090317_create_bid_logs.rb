class CreateBidLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :bid_logs do |t|
      t.integer :auction_id, null: false
      t.integer :user_id, null: false
      t.integer :bid_amount, null: false
      t.datetime :bid_time, null: false

      t.timestamps
    end
    
    add_index :bid_logs, :auction_id
    add_index :bid_logs, :user_id
    add_index :bid_logs, :bid_time
    add_index :bid_logs, [:auction_id, :bid_amount]
  end
end
