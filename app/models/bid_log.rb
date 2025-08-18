class BidLog < ApplicationRecord
  belongs_to :auction
  belongs_to :user
  
  validates :bid_amount, presence: true, numericality: { greater_than: 0 }
  validates :bid_time, presence: true
  
  scope :recent, -> { order(bid_time: :desc) }
  scope :by_auction, ->(auction_id) { where(auction_id: auction_id) }
  
  def formatted_bid_time
    bid_time.strftime("%H:%M:%S")
  end
end
