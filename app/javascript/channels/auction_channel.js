import consumer from "channels/consumer"

consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: 1 }, {
  received(data) {
    // 受け取ったデータを使ってUIを更新
    const currentBidElement = document.getElementById("current_bid");
    if (currentBidElement) {
      currentBidElement.innerText = data.current_bid;
    }
    
    // タイムスタンプの更新（モニター画面用）
    const lastUpdateElement = document.getElementById("last-update");
    if (lastUpdateElement) {
      const now = new Date();
      const timeString = now.toLocaleTimeString('ja-JP', { 
        hour: '2-digit', 
        minute: '2-digit', 
        second: '2-digit' 
      });
      lastUpdateElement.innerText = timeString;
    }
  }
});