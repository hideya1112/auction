class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :auction
  
  validates :message, presence: true
  validates :notification_type, presence: true, inclusion: { in: %w[bid_success hammer_price auction_switch] }
  
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  def mark_as_read!
    update!(read: true)
  end
end
