class AddItemIdToAuctions < ActiveRecord::Migration[8.0]
  def change
    add_column :auctions, :item_id, :integer, null: false, default: 1
    add_index :auctions, :item_id
  end
end
