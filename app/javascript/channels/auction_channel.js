import consumer from "channels/consumer"

consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: 1 }, {
  received(data) {
    // 受け取ったデータを使ってUIを更新
    const currentBidElement = document.getElementById("current_bid");
    if (currentBidElement) {
      currentBidElement.innerText = data.current_bid;
    }
    
    // 最低入札価格の更新
    const minBidElement = document.getElementById("min_bid");
    if (minBidElement) {
      const newMinBid = parseInt(data.current_bid) + 1;
      minBidElement.innerText = newMinBid;
    }
    
    // 入力フィールドのmin属性の更新
    const bidInputElement = document.getElementById("bid_input");
    if (bidInputElement) {
      const newMinBid = parseInt(data.current_bid) + 1;
      bidInputElement.min = newMinBid;
      bidInputElement.placeholder = `最低: ${newMinBid}円`;
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