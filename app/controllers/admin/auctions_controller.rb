class Admin::AuctionsController < Admin::ApplicationController
  include ApplicationHelper
  before_action :set_auction, only: [:show, :edit, :update, :destroy, :hammer_price, :rollback_bid, :next_item]

  def index
    @auctions = Auction.includes(:item).order(created_at: :desc)
  end

  def show
  end

  def new
    @auction = Auction.new
    @items = Item.all
  end

  def create
    @auction = Auction.new(auction_params)
    @items = Item.all

    if @auction.save
      redirect_to admin_auction_path(@auction), notice: 'オークションが正常に作成されました。'
    else
      render :new
    end
  end

  def edit
    @items = Item.all
  end

  def update
    if @auction.update(auction_params)
      redirect_to admin_auction_path(@auction), notice: 'オークションが正常に更新されました。'
    else
      @items = Item.all
      render :edit
    end
  end

  def destroy
    @auction.destroy
    redirect_to admin_auctions_path, notice: 'オークションが削除されました。'
  end

  # ハンマープライス処理
  def hammer_price
    # 最高価格で入札している人数を確認
    highest_bidders_count = @auction.bid_logs.where(bid_amount: @auction.current_bid).select(:user_id).distinct.count
    
    if highest_bidders_count > 1
      redirect_to admin_dashboard_path, alert: "最高価格で#{highest_bidders_count}名が入札しています。ハンマープライスを実行できません。"
      return
    end
    
    if @auction.update(status: 'hammered')
      # 落札者を取得
      winner = @auction.bid_logs.where(bid_amount: @auction.current_bid).order(bid_time: :desc).first&.user
      
      # 落札者に通知を作成
      @auction.create_notification_for_winner
      
      # 全ユーザーにオークション終了を通知
      ActionCable.server.broadcast("auction_#{@auction.id}_channel", {
        current_bid: @auction.current_bid,
        status: @auction.status,
        bidder_count: @auction.current_bidders,
        same_bid_count: @auction.same_bid_count,
        auction_ended: true,
        message: "オークションが終了しました。落札価格: #{format_currency_with_symbol(@auction.current_bid)}",
        winner_id: winner&.id,
        hammer_price: true
      })
      
      redirect_to admin_path, notice: 'ハンマープライスが実行されました。'
    else
      redirect_to admin_path, alert: 'ハンマープライスの実行に失敗しました。'
    end
  end

  # 入札ロールバック処理
  def rollback_bid
    # 最新の入札ログを取得
    latest_bid = @auction.bid_logs.order(bid_time: :desc).first
    
    if latest_bid
      # 最新の入札ログを削除
      latest_bid.destroy
      
      # 現在の入札金額を更新（前の入札金額に戻す）
      previous_bid = @auction.bid_logs.order(bid_time: :desc).first
      if previous_bid
        @auction.update(current_bid: previous_bid.bid_amount)
      else
        # 入札がない場合は開始価格に戻す
        @auction.update(current_bid: @auction.item.starting_price)
      end
      
      # 変更をブロードキャスト
      ActionCable.server.broadcast("auction_#{@auction.id}_channel", {
        current_bid: @auction.current_bid,
        status: @auction.status,
        bidder_count: @auction.current_bidders,
        same_bid_count: @auction.same_bid_count,
        rollback: true,
        message: "入札がロールバックされました。現在価格: #{format_currency_with_symbol(@auction.current_bid)}"
      })
      
      redirect_to admin_path, notice: '入札がロールバックされました。'
    else
      redirect_to admin_path, alert: 'ロールバックする入札がありません。'
    end
  end

  # 次の商品への移行
  def next_item
    # 現在のオークションを完了にする
    @auction.update(status: 'completed')
    
    # 次の商品のオークションを作成または開始
    next_item = Item.where.not(id: @auction.item_id).first
    if next_item
      next_auction = Auction.create!(
        item: next_item,
        current_bid: next_item.starting_price,
        status: 'active'
      )
      
      # 次のオークションへの移行をブロードキャスト
      ActionCable.server.broadcast("auction_#{@auction.id}_channel", {
        next_auction: true,
        next_auction_id: next_auction.id,
        message: "次の商品に移行しました。オークションID: #{next_auction.id}"
      })
      
      redirect_to admin_path, notice: "次の商品（#{next_item.name}）のオークションを開始しました。"
    else
      redirect_to admin_path, alert: '次の商品がありません。'
    end
  end

  # オークション切り替え
  def switch
    # すべてのユーザーに新しいオークションへの移行を通知
    ActionCable.server.broadcast("auction_1_channel", {
      auction_switch: true,
      new_auction_id: @auction.id,
      new_auction_url: participant_auction_path(@auction),
      message: "オークション #{@auction.id} に切り替わりました。"
    })
    
    respond_to do |format|
      format.json { render json: { success: true, message: "オークション #{@auction.id} に切り替えました。" } }
    end
  end

  private

  def set_auction
    @auction = Auction.find(params[:id])
  end

  def auction_params
    params.require(:auction).permit(:item_id, :current_bid, :status)
  end
end
