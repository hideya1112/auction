class Item < ApplicationRecord
  has_many :auctions, dependent: :destroy
  
  validates :name, presence: true
  validates :starting_price, presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { joins(:auctions).where(auctions: { status: 'active' }) }
  scope :completed, -> { joins(:auctions).where(auctions: { status: 'completed' }) }
end
