class AuctionsController < ApplicationController
  include ApplicationHelper
    def show
      @auction = Auction.first
    end

    # 参加者用画面
    def participant
      # ログインしていない場合はログイン画面にリダイレクト
      unless session[:user_id]
        redirect_to user_login_path, alert: '参加者画面にアクセスするにはログインが必要です'
        return
      end
      
      @auction = Auction.find(params[:id])
      # 現在のユーザーが既に入札した金額のリストを取得
      @user_bid_amounts = @auction.bid_logs.where(user_id: session[:user_id]).pluck(:bid_amount)
      # 未読通知数を取得
      @unread_notifications_count = User.find(session[:user_id]).unread_notifications_count
      # オークションの状態をビューに渡す
      @auction_ended = !@auction.active?
    end

    # モニター用画面
    def monitor
      @auction = Auction.find(params[:id])
    end
  
    def update
      # ログインしていない場合はログイン画面にリダイレクト
      unless session[:user_id]
        redirect_to user_login_path, alert: '入札するにはログインが必要です'
        return
      end
      
      @auction = Auction.find(params[:id])
      
      # オークションが終了している場合は入札を拒否
      unless @auction.active?
        respond_to do |format|
          format.html { redirect_to participant_auction_path(@auction), alert: 'このオークションは終了しています' }
          format.json { render json: { success: false, error: 'このオークションは終了しています' } }
        end
        return
      end

      if params[:auction][:current_bid].to_f >= @auction.current_bid
        # 現在ログインしているユーザーのIDを設定
        Thread.current[:current_user_id] = session[:user_id]
        
        # 同じユーザーが同じ金額で既に入札していないかチェック
        if @auction.bid_logs.exists?(user_id: session[:user_id], bid_amount: params[:auction][:current_bid].to_f)
          flash[:alert] = "同じ金額で既に入札済みです"
          respond_to do |format|
            format.html { render :participant }
            format.json { render json: { success: false, error: flash[:alert] } }
          end
          return
        end
        
        # 入札ログを先に作成（同じ金額でもログは作成する）
        bid_log = @auction.bid_logs.create!(
          user_id: session[:user_id],
          bid_amount: params[:auction][:current_bid].to_f,
          bid_time: Time.current
        )
        
        # 入札成功通知を作成
        @auction.notifications.create!(
          user_id: session[:user_id],
          message: "入札が完了しました。入札金額: #{format_currency_with_symbol(params[:auction][:current_bid].to_f)}",
          notification_type: 'bid_success',
          read: false
        )
        
        # 入札金額が現在の金額より大きい場合のみ更新
        if params[:auction][:current_bid].to_f > @auction.current_bid
          @auction.update(current_bid: params[:auction][:current_bid])
        end
        
        # スレッドローカル変数をクリア
        Thread.current[:current_user_id] = nil
        
        # 手動でActionCableのブロードキャストを実行
        ActionCable.server.broadcast("auction_#{@auction.id}_channel", { 
          current_bid: @auction.current_bid,
          status: @auction.status,
          bidder_count: @auction.current_bidders,
          same_bid_count: @auction.same_bid_count
        })
        
        # AJAXリクエストの場合はJSONレスポンスを返す
        respond_to do |format|
          format.html { redirect_to participant_auction_path(@auction), notice: '入札が完了しました' }
          format.json { render json: { success: true, current_bid: @auction.current_bid, bidder_count: @auction.current_bidders, same_bid_count: @auction.same_bid_count } }
        end
      else
        flash[:alert] = "入札金額は現在の金額以上でなければなりません"
        respond_to do |format|
          format.html { render :participant }
          format.json { render json: { success: false, error: flash[:alert] } }
        end
      end
    end
  end
