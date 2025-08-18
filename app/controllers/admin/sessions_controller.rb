class Admin::SessionsController < ApplicationController
  def new
    # ログイン画面を表示
  end
  
  def create
    if params[:username] == 'admin' && params[:password] == 'password123'
      session[:admin_logged_in] = true
      redirect_to admin_path, notice: 'ログインしました'
    else
      flash.now[:alert] = 'ユーザー名またはパスワードが正しくありません'
      render :new
    end
  end
  
  def destroy
    session[:admin_logged_in] = nil
    redirect_to admin_login_path, notice: 'ログアウトしました'
  end
end
