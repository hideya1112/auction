class Auction < ApplicationRecord
  include ApplicationHelper
  
  belongs_to :item
  has_many :bid_logs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  after_update_commit :broadcast_current_bid
  # create_bid_log はコントローラーで手動実行するため無効化
  # after_update_commit :create_bid_log, if: :saved_change_to_current_bid?
  
  validates :current_bid, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive hammered] }
  
  # hammeredのオークションはactiveに変更できない
  validate :cannot_activate_hammered_auction, on: :update
  
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :hammered, -> { where(status: 'hammered') }
  
  def active?
    status == 'active'
  end
  
  def inactive?
    status == 'inactive'
  end
  
  def hammered?
    status == 'hammered'
  end
  
  def min_bid_amount
    current_bid + 1
  end
  
  def bidder_count
    # 現在の入札金額に到達するまでの入札に参加したユーザー数
    bid_logs.where('bid_amount <= ?', current_bid).select(:user_id).distinct.count
  end
  
  def current_bidders
    # 現在の入札金額に到達するまでの入札に参加したユーザー数（bidder_countと同じ）
    bid_logs.where('bid_amount <= ?', current_bid).select(:user_id).distinct.count
  end
  
  def same_bid_count
    # 現在の入札金額と同じ金額で入札している人の数
    # 最新の入札金額（current_bid）と同じ金額で入札した人の数を計算
    bid_logs.where(bid_amount: current_bid).select(:user_id).distinct.count
  end
  
  def create_notification_for_winner
    # ハンマープライス時に落札者に通知を作成
    if status == 'hammered'
      winner = bid_logs.where(bid_amount: current_bid).order(bid_time: :desc).first&.user
      if winner
        notifications.create!(
          user: winner,
          message: "おめでとうございます！落札されました。落札価格: #{format_currency_with_symbol(current_bid)}",
          notification_type: 'hammer_price',
          read: false
        )
      end
    end
  end
  
  private
  
  def cannot_activate_hammered_auction
    if status_changed? && status == 'active' && status_was == 'hammered'
      errors.add(:status, 'ハンマープライス済みのオークションはアクティブにできません')
    end
  end
  
  def broadcast_current_bid
    # idが存在することを確認
    if id.present?
      ActionCable.server.broadcast("auction_#{id}_channel", { 
        current_bid: current_bid,
        status: status,
        bidder_count: current_bidders,
        same_bid_count: same_bid_count
      })
    else
      Rails.logger.error "Auction ID is nil. Cannot broadcast current bid."
    end
  end
  
  def create_bid_log
    # 現在ログインしているユーザーのIDを取得
    user_id = Thread.current[:current_user_id]
    
    if user_id
      # 入札ログを作成
      bid_logs.create!(
        user_id: user_id,
        bid_amount: current_bid,
        bid_time: Time.current
      )
    end
  end
end
