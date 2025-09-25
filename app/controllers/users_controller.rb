class UsersController < ApplicationController
  def login
    # 既にログインしている場合は参加者画面にリダイレクト
    if session[:user_id]
      redirect_to participant_auction_path(Auction.active.first), notice: "既にログインしています"
    end
  end
  
  def authenticate
    user = User.find_by(user_id: params[:user_id])
    
    if user
      session[:user_id] = user.id
      session[:user_name] = user.name
      redirect_to participant_auction_path(Auction.active.first), notice: "#{user.name}様、ようこそ！"
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
