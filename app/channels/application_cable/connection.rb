module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # セッションからユーザーIDを取得（簡易版）
      user_id = request.session[:user_id]
      
      if user_id
        User.find_by(id: user_id)
      else
        # 認証なしでも接続を許可（デバッグ用）
        nil
      end
    end
  end
end
