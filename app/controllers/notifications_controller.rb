class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = current_user.notifications.recent.page(params[:page]).per(20)
    @unread_count = current_user.unread_notifications_count
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read! unless @notification.read?
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read: true)
    redirect_to notifications_path, notice: 'すべての通知を既読にしました。'
  end

  def destroy
    @notification = current_user.notifications.find(params[:id])
    @notification.destroy
    redirect_to notifications_path, notice: '通知を削除しました。'
  end

  def unread_count
    count = current_user.unread_notifications_count
    respond_to do |format|
      format.json { render json: { count: count } }
      format.html { redirect_to user_login_path, alert: 'ログインが必要です' }
    end
  end

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def require_login
    unless session[:user_id]
      redirect_to user_login_path, alert: '通知を表示するにはログインが必要です'
    end
  end
end
