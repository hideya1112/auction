class Admin::BidLogsController < Admin::ApplicationController
  include ApplicationHelper
  def index
    @bid_logs = BidLog.includes(:user, :auction)
                      .order(bid_time: :desc)
                      .page(params[:page])
                      .per(50)
    
    # フィルタリング機能
    if params[:auction_id].present?
      @bid_logs = @bid_logs.where(auction_id: params[:auction_id])
    end
    
    if params[:user_id].present?
      @bid_logs = @bid_logs.where(user_id: params[:user_id])
    end
    
    if params[:date_from].present?
      @bid_logs = @bid_logs.where('bid_time >= ?', Date.parse(params[:date_from]).beginning_of_day)
    end
    
    if params[:date_to].present?
      @bid_logs = @bid_logs.where('bid_time <= ?', Date.parse(params[:date_to]).end_of_day)
    end
    
    # 統計情報
    @total_bids = @bid_logs.count
    @total_amount = @bid_logs.sum(:bid_amount)
    @unique_users = @bid_logs.select(:user_id).distinct.count
    
    # フィルター用のデータ
    @auctions = Auction.includes(:item).order(created_at: :desc)
    @users = User.order(:name)
  end

  def show
    @bid_log = BidLog.includes(:user, :auction).find(params[:id])
  end

  def destroy
    @bid_log = BidLog.find(params[:id])
    auction = @bid_log.auction
    
    if @bid_log.destroy
      # オークションの現在価格を再計算
      latest_bid = auction.bid_logs.order(bid_time: :desc).first
      if latest_bid
        auction.update(current_bid: latest_bid.bid_amount)
      else
        auction.update(current_bid: auction.item.starting_price)
      end
      
      # 変更をブロードキャスト
      ActionCable.server.broadcast("auction_#{auction.id}_channel", {
        current_bid: auction.current_bid,
        status: auction.status,
        bidder_count: auction.current_bidders,
        same_bid_count: auction.same_bid_count,
        bid_deleted: true,
        message: "入札が削除されました。現在価格: #{format_currency_with_symbol(auction.current_bid)}"
      })
      
      redirect_to admin_bid_logs_path, notice: '入札ログが削除されました。'
    else
      redirect_to admin_bid_logs_path, alert: '入札ログの削除に失敗しました。'
    end
  end

  private

  def bid_log_params
    params.require(:bid_log).permit(:user_id, :auction_id, :bid_amount, :bid_time)
  end
end
