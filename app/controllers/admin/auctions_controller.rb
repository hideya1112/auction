class Admin::AuctionsController < Admin::ApplicationController
  include ApplicationHelper
  before_action :set_auction, only: [:show, :edit, :update, :destroy, :hammer_price, :rollback_bid, :next_item, :switch]

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
    # 入札ログが存在するかチェック
    if @auction.bid_logs.count == 0
      redirect_to admin_dashboard_path, alert: "入札が一度もありません。ハンマープライスを実行できません。"
      return
    end
    
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
        starting_price: @auction.item.starting_price,
        bid_logs_count: @auction.bid_logs.count,
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

  # 次のオークションへの移行
  def next_item
    # 現在のオークションをinactiveにする
    @auction.update(status: 'inactive')
    
    # 次の商品のオークションを探す（既存のオークションを再利用）
    next_item = Item.where.not(id: @auction.item_id).first
    if next_item
      # 既存のオークションを探す
      next_auction = Auction.find_by(item: next_item)
      
      if next_auction
        # 既存のオークションをactiveに設定
        next_auction.update!(status: 'active', current_bid: next_item.starting_price)
      else
        # 新しいオークションを作成
        next_auction = Auction.create!(
          item: next_item,
          current_bid: next_item.starting_price,
          status: 'active'
        )
      end
      
      # 他のオークションをinactiveに設定
      Auction.where.not(id: [@auction.id, next_auction.id]).update_all(status: 'inactive')
      
      # 全ユーザーに新しいオークションへの移行を通知
      ActionCable.server.broadcast("auction_#{@auction.id}_channel", {
        auction_switch: true,
        new_auction_id: next_auction.id,
        new_auction_url: participant_auction_path(next_auction),
        new_monitor_url: monitor_auction_path(next_auction),
        message: "次のオークション（#{next_item.name}）に移行しました。"
      })
      
      respond_to do |format|
        format.html { redirect_to admin_path, notice: "次のオークション（#{next_item.name}）を開始しました。全ユーザーが新しいオークションに移行します。" }
        format.json { render json: { success: true, message: "次のオークション（#{next_item.name}）を開始しました。" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_path, alert: '次の商品がありません。' }
        format.json { render json: { success: false, error: '次の商品がありません。' } }
      end
    end
  end

  # オークション切り替え（手動切り替え用）
  def switch
    Rails.logger.info "=== Switch Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Request format: #{request.format}"
    Rails.logger.info "Content-Type: #{request.content_type}"
    
    new_auction_id = params[:new_auction_id] || params[:auction][:new_auction_id]
    Rails.logger.info "New auction ID: #{new_auction_id}"
    
    begin
      new_auction = Auction.find(new_auction_id)
      Rails.logger.info "New auction found: #{new_auction.id} - #{new_auction.item.name} (status: #{new_auction.status})"
      
      # hammeredのオークションはactiveにできない
      if new_auction.hammered?
        error_message = "ハンマープライス済みのオークション（ID: #{new_auction.id}）はアクティブにできません。"
        Rails.logger.error error_message
        
        respond_to do |format|
          format.html { redirect_to admin_path, alert: error_message }
          format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
        end
        return
      end
      
      # 現在のオークションをinactiveにする（hammeredの場合はそのまま）
      if @auction.active?
        @auction.update(status: 'inactive')
        Rails.logger.info "Current auction #{@auction.id} set to inactive"
      else
        Rails.logger.info "Current auction #{@auction.id} status remains #{@auction.status}"
      end
      
      # 新しいオークションをアクティブにする（inactiveのもののみ）
      if new_auction.inactive?
        new_auction.update!(status: 'active')
        Rails.logger.info "New auction #{new_auction.id} set to active"
      else
        error_message = "オークション（ID: #{new_auction.id}）は既に#{new_auction.status}状態です。"
        Rails.logger.error error_message
        
        respond_to do |format|
          format.html { redirect_to admin_path, alert: error_message }
          format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
        end
        return
      end
      
      # 他のオークションをinactiveに設定（activeは1つだけ、hammeredはそのまま）
      Auction.where.not(id: [@auction.id, new_auction.id]).where.not(status: 'hammered').update_all(status: 'inactive')
      Rails.logger.info "Other auctions set to inactive (hammered auctions remain unchanged)"
      
      # 全ユーザーに新しいオークションへの移行を通知
      # 全オークションチャンネルに通知を送信（確実に届くように）
      Auction.all.each do |auction|
        ActionCable.server.broadcast("auction_#{auction.id}_channel", {
          auction_switch: true,
          new_auction_id: new_auction.id,
          new_auction_url: participant_auction_path(new_auction),
          new_monitor_url: monitor_auction_path(new_auction),
          message: "オークション #{new_auction.id}（#{new_auction.item.name}）に切り替わりました。"
        })
      end
      
      Rails.logger.info "ActionCable broadcast sent to all auction channels"
      
      respond_to do |format|
        format.html { 
          Rails.logger.info "Responding with HTML redirect"
          redirect_to admin_path, notice: "オークション #{new_auction.id}（#{new_auction.item.name}）に切り替えました。" 
        }
        format.json { 
          Rails.logger.info "Responding with JSON"
          render json: { success: true, message: "オークション #{new_auction.id}（#{new_auction.item.name}）に切り替えました。" } 
        }
      end
    rescue => e
      Rails.logger.error "Error in switch action: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.html { redirect_to admin_path, alert: "エラーが発生しました: #{e.message}" }
        format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
      end
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
