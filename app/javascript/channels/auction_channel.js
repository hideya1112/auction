import consumer from "channels/consumer"

consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: 1 }, {
  received(data) {
    // 受け取ったデータを使ってUIを更新
    document.getElementById("current_bid").innerText = data.current_bid;
  }
});