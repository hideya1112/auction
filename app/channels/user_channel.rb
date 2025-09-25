class UserChannel < ApplicationCable::Channel
  def subscribed
    # ログインしているユーザーのみが自分のチャンネルに接続可能
    if current_user
      stream_from "user_#{current_user.id}_channel"
      Rails.logger.info "User #{current_user.id} subscribed to user channel"
    else
      # デバッグ用：認証なしでも接続を許可
      Rails.logger.info "Anonymous user subscribed to user channel"
    end
  end

  def unsubscribed
    Rails.logger.info "User #{current_user&.id} unsubscribed from user channel"
  end
end
