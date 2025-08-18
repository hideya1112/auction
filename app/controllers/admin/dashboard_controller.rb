class Admin::DashboardController < Admin::ApplicationController
  def index
    @current_auction = Auction.active.first
    @items = Item.all
    @recent_bids = BidLog.includes(:user, :auction).recent.limit(10)
  end
end
