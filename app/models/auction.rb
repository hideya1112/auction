class Auction < ApplicationRecord
  belongs_to :item
  has_many :bid_logs, dependent: :destroy
  
  after_update_commit :broadcast_current_bid
  after_update_commit :create_bid_log, if: :saved_change_to_current_bid?
  
  validates :current_bid, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active completed hammered] }
  
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :hammered, -> { where(status: 'hammered') }
  
  def active?
    status == 'active'
  end
  
  def completed?
    status == 'completed'
  end
  
  def hammered?
    status == 'hammered'
  end
  
  def min_bid_amount
    current_bid + 1
  end
  
  def bidder_count
    bid_logs.select(:user_id).distinct.count
  end
  
  def current_bidders
    bid_logs.where(bid_amount: current_bid).select(:user_id).distinct.count
  end
  
  private
  
  def broadcast_current_bid
    # idが存在することを確認
    if id.present?
      ActionCable.server.broadcast("auction_#{id}_channel", { 
        current_bid: current_bid,
        status: status,
        bidder_count: current_bidders
      })
    else
      Rails.logger.error "Auction ID is nil. Cannot broadcast current bid."
    end
  end
  
  def create_bid_log
    # 入札ログの作成は別途実装
    # ここでは最低限の処理のみ
  end
end
