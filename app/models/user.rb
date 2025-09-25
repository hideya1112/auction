class User < ApplicationRecord
  has_many :bid_logs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  validates :user_id, presence: true, uniqueness: true
  validates :name, presence: true
  
  def display_name
    "#{name} (#{user_id})"
  end
  
  def unread_notifications_count
    notifications.unread.count
  end
end
