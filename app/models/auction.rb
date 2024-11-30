class Auction < ApplicationRecord
    after_update_commit :broadcast_current_bid
    private

    def broadcast_current_bid
        # idが存在することを確認
        if id.present?
          ActionCable.server.broadcast("auction_#{id}_channel", { current_bid: current_bid })
        else
          Rails.logger.error "Auction ID is nil. Cannot broadcast current bid."
        end
      end
end
