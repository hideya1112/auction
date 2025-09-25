class UsersController < ApplicationController
  def login
    # 既にログインしている場合は参加者画面にリダイレクト
    if session[:user_id]
      auction = Auction.active.first || Auction.first
      if auction
        redirect_to participant_auction_path(auction), notice: "既にログインしています"
      else
        redirect_to user_login_path, alert: "オークションが存在しません"
      end
    end
    
    # モニター画面用のオークションを取得
    @auction = Auction.active.first || Auction.first
  end
  
  def authenticate
    user = User.find_by(user_id: params[:user_id])
    
    if user
      session[:user_id] = user.id
      session[:user_name] = user.name
      auction = Auction.active.first || Auction.first
      if auction
        redirect_to participant_auction_path(auction), notice: "#{user.name}様、ようこそ！"
      else
        redirect_to user_login_path, alert: "オークションが存在しません"
      end
    else
      flash.now[:alert] = 'ユーザーIDが見つかりません'
      render :login
    end
  end
  
  def logout
    session[:user_id] = nil
    session[:user_name] = nil
    redirect_to user_login_path, notice: 'ログアウトしました'
  end
end
