class UsersController < ApplicationController
  def login
    # ログイン画面を表示
  end
  
  def authenticate
    user = User.find_by(user_id: params[:user_id])
    
    if user
      session[:user_id] = user.id
      session[:user_name] = user.name
      redirect_to participant_auction_path(Auction.active.first), notice: "#{user.name}さん、ようこそ！"
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
