class CreateAuctions < ActiveRecord::Migration[8.0]
  def change
    create_table :auctions do |t|
      t.bigint :current_bid, null: false

      t.timestamps
    end
  end
end
