class AuctionChannel < ApplicationCable::Channel
  def subscribed
    # params[:auction_id]を使って、接続するオークションを動的に選択
    @auction = Auction.find_by(id: params[:auction_id])
    if @auction
      # オークションIDを基にストリームを開始
      stream_from "auction_#{@auction.id}_channel"
    else
      # オークションが存在しない場合、エラーメッセージを表示
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
