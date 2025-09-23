class AuctionsController < ApplicationController
    def show
      @auction = Auction.first
    end

    # 参加者用画面
    def participant
      @auction = Auction.find(params[:id])
    end

    # モニター用画面
    def monitor
      @auction = Auction.find(params[:id])
    end
  
    def update
      @auction = Auction.find(params[:id])

      if params[:auction][:current_bid].to_f >= @auction.current_bid
        # 現在ログインしているユーザーのIDを設定
        Thread.current[:current_user_id] = session[:user_id]
        
        @auction.update(current_bid: params[:auction][:current_bid])
        
        # スレッドローカル変数をクリア
        Thread.current[:current_user_id] = nil
      else
        flash[:alert] = "入札金額は現在の金額以上でなければなりません"
        render :show
      end
    end
  end
