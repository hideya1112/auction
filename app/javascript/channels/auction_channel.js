import consumer from "channels/consumer"

// 効果音の初期化
let bidSound;
try {
  bidSound = new Audio('/assets/bid_sound.mp3');
  bidSound.volume = 0.5; // 音量を50%に設定
} catch (e) {
  console.log('効果音の読み込みに失敗しました:', e);
}

// ATM風キーパッドの処理
let currentAmount = 0;

// 最低入札価格を取得する関数
function getMinBid() {
  return parseInt(document.getElementById('bid_input')?.min || 0);
}

// 金額表示の更新
function updateAmountDisplay() {
  const display = document.getElementById('amount_display');
  if (display) {
    display.textContent = currentAmount.toLocaleString();
  }
  
  // 入札ボタンの有効/無効を制御
  const submitBtn = document.getElementById('submit_btn');
  if (submitBtn) {
    submitBtn.disabled = currentAmount < getMinBid();
  }
}

// グローバル関数として定義（ActionCableから呼び出し可能にする）
window.updateAmountDisplay = updateAmountDisplay;

// キーパッドのイベントリスナーを設定する関数
function setupKeypadListeners() {
  // 既存のイベントリスナーを削除（重複を防ぐため）
  document.querySelectorAll('.keypad-btn[data-number]').forEach(btn => {
    btn.replaceWith(btn.cloneNode(true));
  });
  
  document.getElementById('clear_btn')?.replaceWith(document.getElementById('clear_btn').cloneNode(true));
  document.getElementById('backspace_btn')?.replaceWith(document.getElementById('backspace_btn').cloneNode(true));
  document.getElementById('submit_btn')?.replaceWith(document.getElementById('submit_btn').cloneNode(true));
  
  // 数字キーの処理
  document.querySelectorAll('.keypad-btn[data-number]').forEach(btn => {
    btn.addEventListener('click', function() {
      const number = parseInt(this.dataset.number);
      const newAmount = currentAmount * 10 + number;
      
      // 最大桁数制限（10桁）
      if (newAmount.toString().length <= 10) {
        currentAmount = newAmount;
        updateAmountDisplay();
      }
    });
  });
  
  // クリアボタン
  document.getElementById('clear_btn')?.addEventListener('click', function() {
    currentAmount = 0;
    updateAmountDisplay();
  });
  
  // バックスペースボタン
  document.getElementById('backspace_btn')?.addEventListener('click', function() {
    currentAmount = Math.floor(currentAmount / 10);
    updateAmountDisplay();
  });
  
  
  // 入札ボタン
  document.getElementById('submit_btn')?.addEventListener('click', function() {
    if (currentAmount >= getMinBid()) {
      console.log('入札開始:', currentAmount, '最低価格:', getMinBid());
      
      // 隠しフィールドに値を設定
      const bidInput = document.getElementById('bid_input');
      if (bidInput) {
        bidInput.value = currentAmount;
        console.log('隠しフィールドに設定:', bidInput.value);
        
        // フォームを送信
        const bidForm = document.getElementById('bid_form');
        if (bidForm) {
          const formData = new FormData(bidForm);
          console.log('送信データ:', Object.fromEntries(formData));
          
          fetch(bidForm.action, {
            method: 'PATCH',
            body: formData,
            headers: {
              'X-Requested-With': 'XMLHttpRequest',
              'Accept': 'application/json'
            }
          })
          .then(response => {
            console.log('レスポンス受信:', response.status);
            return response.json();
          })
          .then(data => {
            console.log('レスポンスデータ:', data);
            if (data.success) {
              // 入札成功時の処理
              currentAmount = 0;
              updateAmountDisplay();
              console.log('入札が完了しました');
            } else {
              alert(data.error || '入札に失敗しました');
            }
          })
          .catch(error => {
            console.error('入札エラー:', error);
            alert('入札に失敗しました');
          });
        }
      }
    } else {
      console.log('入札金額が不足:', currentAmount, '最低価格:', getMinBid());
    }
  });
  
  // 初期表示の更新
  updateAmountDisplay();
}

// ページ読み込み時とページ遷移時にイベントリスナーを設定
document.addEventListener('DOMContentLoaded', setupKeypadListeners);

// Turboのページ遷移時にもイベントリスナーを設定
document.addEventListener('turbo:load', setupKeypadListeners);

const subscription = consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: 1 }, {
  connected() {
    console.log('ActionCable接続成功');
  },
  
  disconnected() {
    console.log('ActionCable接続切断');
  },
  
  rejected() {
    console.log('ActionCable接続拒否');
  },
  
  received(data) {
    console.log('ActionCable受信:', data);
    
    // 受け取ったデータを使ってUIを更新
    const currentBidElement = document.getElementById("current_bid");
    if (currentBidElement) {
      // 参加者画面では通貨記号付きで表示
      if (document.querySelector('.participant-view')) {
        currentBidElement.innerText = `JPY ${data.current_bid.toLocaleString()}`;
      } else {
        // モニター画面では数値のみ
        currentBidElement.innerText = data.current_bid.toLocaleString();
      }
      console.log('現在価格更新:', data.current_bid);
    }
    
    // 入札者数の更新
    const bidderCountElement = document.getElementById("bidder_count");
    if (bidderCountElement && data.bidder_count !== undefined) {
      bidderCountElement.innerText = data.bidder_count;
    } else if (bidderCountElement) {
      // データがない場合は1を表示（最低1人は入札している）
      bidderCountElement.innerText = "1";
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
      
      // ATM風キーパッドの最低入札価格も更新
      const minBid = newMinBid;
      const submitBtn = document.getElementById('submit_btn');
      if (submitBtn) {
        // 現在の金額を取得してボタンの有効/無効を制御
        const currentAmount = parseInt(document.getElementById('amount_display')?.textContent?.replace(/,/g, '') || 0);
        submitBtn.disabled = currentAmount < minBid;
        
        // グローバル変数も更新（他の関数で使用される可能性があるため）
        if (window.updateAmountDisplay) {
          window.updateAmountDisplay();
        }
      }
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