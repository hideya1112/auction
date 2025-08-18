class AddStatusToAuctions < ActiveRecord::Migration[8.0]
  def change
    add_column :auctions, :status, :string, null: false, default: 'active'
    add_index :auctions, :status
  end
end
