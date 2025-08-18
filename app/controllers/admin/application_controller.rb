class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  
  private
  
  def authenticate_admin!
    unless session[:admin_logged_in]
      redirect_to admin_login_path, alert: '管理者としてログインしてください'
    end
  end
end
