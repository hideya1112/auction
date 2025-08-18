import consumer from "channels/consumer"

// 効果音の初期化
let bidSound;
try {
  bidSound = new Audio('/assets/bid_sound.mp3');
  bidSound.volume = 0.5; // 音量を50%に設定
} catch (e) {
  console.log('効果音の読み込みに失敗しました:', e);
}

consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: 1 }, {
  received(data) {
    // 受け取ったデータを使ってUIを更新
    const currentBidElement = document.getElementById("current_bid");
    if (currentBidElement) {
      currentBidElement.innerText = data.current_bid.toLocaleString();
    }
    
    // 入札者数の更新
    const bidderCountElement = document.getElementById("bidder_count");
    if (bidderCountElement && data.bidder_count !== undefined) {
      bidderCountElement.innerText = data.bidder_count;
    } else if (bidderCountElement) {
      // データがない場合は1を表示（最低1人は入札している）
      bidderCountElement.innerText = "1";
    }
    
    // 入札が発生した場合、入札者数を増加
    if (bidderCountElement && data.current_bid) {
      const currentCount = parseInt(bidderCountElement.innerText) || 1;
      // 新しい入札が発生した場合、入札者数を1増やす
      if (data.current_bid > (parseInt(document.getElementById("current_bid")?.innerText.replace(/,/g, '')) || 0)) {
        bidderCountElement.innerText = currentCount + 1;
      }
    }
    
    // 最低入札価格の更新
    const minBidElement = document.getElementById("min_bid");
    if (minBidElement) {
      const newMinBid = parseInt(data.current_bid) + 1;
      minBidElement.innerText = `JPY ${newMinBid.toLocaleString()}`;
    }
    
    // 入力フィールドのmin属性の更新
    const bidInputElement = document.getElementById("bid_input");
    if (bidInputElement) {
      const newMinBid = parseInt(data.current_bid) + 1;
      bidInputElement.min = newMinBid;
      bidInputElement.placeholder = `最低: ${newMinBid.toLocaleString()}円`;
    }
    
    // 効果音の再生（モニター画面でのみ）
    if (bidSound && document.querySelector('.monitor-view')) {
      try {
        bidSound.currentTime = 0; // 音声を最初から再生
        bidSound.play();
      } catch (e) {
        console.log('効果音の再生に失敗しました:', e);
      }
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