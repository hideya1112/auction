class CreateAuctions < ActiveRecord::Migration[8.0]
  def change
    create_table :auctions do |t|
      t.decimal :current_bid

      t.timestamps
    end
  end
end
