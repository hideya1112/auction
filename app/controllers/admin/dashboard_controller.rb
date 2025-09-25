class Admin::DashboardController < Admin::ApplicationController
  def index
    # アクティブまたはハンマープライス済みのオークションを取得
    @current_auction = Auction.active.first || Auction.hammered.first
    @items = Item.all
    @recent_bids = BidLog.includes(:user, :auction).recent.limit(10)
  end
end
