import consumer from "channels/consumer"

// 管理画面では実行しない
if (window.location.pathname.includes('/admin/') || window.DISABLE_ACTIONCABLE) {
  console.log('管理画面のため、monitor_channel.js をスキップします');
  // 管理画面では何もしない
} else {
  console.log('モニター画面でmonitor_channel.js を実行します');

// 効果音の初期化（モニター画面専用）
let bidSound;
try {
  bidSound = new Audio('/sounds/bid_sound.mp3');
  bidSound.volume = 0.8; // モニター画面では少し大きめに設定
  
  // 音声ファイルの読み込み完了を待つ
  bidSound.addEventListener('canplaythrough', () => {
    console.log('モニター画面：効果音の読み込み完了');
  });
  
  bidSound.addEventListener('error', (e) => {
    console.log('モニター画面：効果音の読み込みエラー:', e);
  });
  
  console.log('モニター画面：効果音を初期化しました');
} catch (e) {
  console.log('モニター画面：効果音の読み込みに失敗しました:', e);
}

// オークションチャンネル（モニター画面専用）
const subscription = consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: 1 }, {
  connected() {
    console.log('モニター画面：ActionCable接続成功');
  },
  
  disconnected() {
    console.log('モニター画面：ActionCable接続切断');
  },
  
  rejected() {
    console.log('モニター画面：ActionCable接続拒否');
  },
  
  received(data) {
    console.log('モニター画面：ActionCable受信:', data);
    
    // 受け取ったデータを使ってUIを更新
    const currentBidElement = document.getElementById("current_bid");
    if (currentBidElement) {
      currentBidElement.innerText = data.current_bid.toLocaleString();
      console.log('モニター画面：現在価格更新:', data.current_bid);
    }
    
    // 入札者数の更新
    const bidderCountElement = document.getElementById("bidder_count");
    if (bidderCountElement && data.bidder_count !== undefined) {
      bidderCountElement.innerText = data.bidder_count;
    } else if (bidderCountElement) {
      bidderCountElement.innerText = "1";
    }
    
    // 複数入札者数の更新
    const sameBidCountElement = document.getElementById("same_bid_count");
    const sameBidInfoElement = document.getElementById("same_bid_info");
    if (sameBidCountElement && data.same_bid_count !== undefined) {
      sameBidCountElement.innerText = data.same_bid_count;
      
      if (sameBidInfoElement) {
        if (data.same_bid_count >= 2) {
          sameBidInfoElement.style.display = "block";
        } else {
          sameBidInfoElement.style.display = "none";
        }
      }
    }
    
    // オークション終了表示の更新
    const hammerPriceInfoElement = document.getElementById("hammer_price_info");
    if (hammerPriceInfoElement) {
      if (data.auction_ended || data.status === 'hammered' || data.status === 'completed') {
        hammerPriceInfoElement.style.display = "block";
        hammerPriceInfoElement.innerHTML = '<span class="hammer-price-text">🔨 オークション終了</span>';
      } else {
        hammerPriceInfoElement.style.display = "none";
      }
    }
    
    // タイムスタンプの更新
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
    
    // モニター画面でのみ効果音を再生
    if (bidSound) {
      try {
        bidSound.currentTime = 0; // 音声を最初から再生
        const playPromise = bidSound.play();
        
        if (playPromise !== undefined) {
          playPromise.then(() => {
            console.log('モニター画面：効果音を再生しました');
          }).catch(error => {
            console.log('モニター画面：効果音の再生に失敗しました:', error);
          });
        }
      } catch (e) {
        console.log('モニター画面：効果音の再生に失敗しました:', e);
      }
    } else {
      console.log('モニター画面：効果音オブジェクトが存在しません');
    }
    
    // オークション切り替えの処理
    if (data.auction_switch) {
      if (confirm(data.message + '\n\n新しいオークションに移動しますか？')) {
        window.location.href = data.new_auction_url;
      }
    }
  }
});
}
