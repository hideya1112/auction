import consumer from "channels/consumer"

// 管理画面では実行しない
if (window.location.pathname.includes('/admin/') || window.DISABLE_ACTIONCABLE) {
  console.log('管理画面のため、auction_channel.js をスキップします');
  // 管理画面では何もしない
} else {
  console.log('ユーザー画面でauction_channel.js を実行します');
  
  // 効果音はモニター画面専用のため削除

  // ATM風キーパッドの処理
  let currentAmount = 0;
  let userBidAmounts = []; // ユーザーが既に入札した金額のリスト
  let auctionEnded = false; // オークション終了状態を管理
  let unreadNotificationCount = 0; // 未読通知数

// 最低入札価格を取得する関数（同じ金額でも入札可能）
function getMinBid() {
  return parseInt(document.getElementById('bid_input')?.min || 0);
}

// 重複入札チェック関数
function isDuplicateBid(amount) {
  return userBidAmounts.includes(amount);
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
    const isMinBidValid = currentAmount >= getMinBid();
    const isNotDuplicate = !isDuplicateBid(currentAmount);
    submitBtn.disabled = !isMinBidValid || !isNotDuplicate;
    
    // 重複入札の場合はボタンテキストを変更
    if (isMinBidValid && !isNotDuplicate) {
      submitBtn.textContent = '既に入札済み';
      submitBtn.style.backgroundColor = '#e74c3c';
    } else {
      submitBtn.textContent = '入札する';
      submitBtn.style.backgroundColor = '#2c3e50';
    }
  }
}

// グローバル関数として定義（ActionCableから呼び出し可能にする）
window.updateAmountDisplay = updateAmountDisplay;

// 通知バッジを更新する関数
function updateNotificationBadge() {
  // ローカルで通知数を増加
  unreadNotificationCount += 1;
  
  const notificationBadge = document.querySelector('.notification-badge');
  if (notificationBadge) {
    if (unreadNotificationCount > 0) {
      notificationBadge.textContent = unreadNotificationCount;
      notificationBadge.style.display = 'inline';
    } else {
      notificationBadge.style.display = 'none';
    }
  }
}

// オークション状態をチェックする関数
function checkAuctionStatus() {
  const hammerPriceInfoElement = document.getElementById("hammer_price_info");
  const bidForm = document.querySelector('.bid-form');
  
  // サーバーから渡されたオークション終了状態をチェック
  if (bidForm && bidForm.dataset.auctionEnded === 'true') {
    console.log('サーバーからオークション終了状態を検出');
    disableBidForm();
    return;
  }
  
  // 既にオークション終了表示がされている場合はキーパッドを無効化
  if (hammerPriceInfoElement && hammerPriceInfoElement.style.display === "block") {
    console.log('オークション終了表示を検出');
    disableBidForm();
  }
}

// 入札フォームを無効化する関数
function disableBidForm() {
  auctionEnded = true; // オークション終了状態を設定
  
  const bidForm = document.querySelector('.bid-form');
  if (bidForm) {
    bidForm.style.opacity = "0.5";
    bidForm.style.pointerEvents = "none";
    
    // フォーム送信を完全に無効化
    bidForm.addEventListener('submit', function(e) {
      e.preventDefault();
      e.stopPropagation();
      console.log('オークション終了のためフォーム送信をブロック');
      return false;
    }, true);
  }
  
  // キーパッドの全ボタンを無効化
  document.querySelectorAll('.keypad-btn').forEach(btn => {
    btn.disabled = true;
    btn.style.opacity = "0.5";
    btn.style.cursor = "not-allowed";
  });
  
  // 入札ボタンを無効化
  const submitBtn = document.getElementById('submit_btn');
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.style.opacity = "0.5";
    submitBtn.style.cursor = "not-allowed";
    submitBtn.textContent = "オークション終了";
  }
  
  // 金額表示をリセット
  currentAmount = 0;
  updateAmountDisplay();
}

// 入札フォームを有効化する関数
function enableBidForm() {
  auctionEnded = false; // オークション終了状態をリセット
  
  const bidForm = document.querySelector('.bid-form');
  if (bidForm) {
    bidForm.style.opacity = "1";
    bidForm.style.pointerEvents = "auto";
    
    // フォーム送信のイベントリスナーを削除（無効化時に追加したものを削除）
    // 注意: 完全に削除するのは難しいため、有効化時は既存のイベントリスナーに依存
  }
  
  // キーパッドの全ボタンを有効化
  document.querySelectorAll('.keypad-btn').forEach(btn => {
    btn.disabled = false;
    btn.style.opacity = "1";
    btn.style.cursor = "pointer";
  });
  
  // 入札ボタンを有効化
  const submitBtn = document.getElementById('submit_btn');
  if (submitBtn) {
    submitBtn.disabled = false;
    submitBtn.style.opacity = "1";
    submitBtn.style.cursor = "pointer";
    submitBtn.textContent = "入札する";
  }
}

// キーパッドのイベントリスナーを設定する関数
function setupKeypadListeners() {
  // ユーザーの入札履歴を初期化
  const bidForm = document.querySelector('.bid-form[data-user-bid-amounts]');
  if (bidForm) {
    try {
      userBidAmounts = JSON.parse(bidForm.dataset.userBidAmounts || '[]');
      console.log('ユーザーの入札履歴:', userBidAmounts);
    } catch (e) {
      console.error('入札履歴の解析に失敗:', e);
      userBidAmounts = [];
    }
    
    // 初期通知数を設定
    unreadNotificationCount = parseInt(bidForm.dataset.unreadCount || '0');
    console.log('初期通知数:', unreadNotificationCount);
  }
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
      // オークション終了時は入力を無視
      if (this.disabled) return;
      
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
    // オークション終了時は入力を無視
    if (this.disabled) return;
    
    currentAmount = 0;
    updateAmountDisplay();
  });
  
  // バックスペースボタン
  document.getElementById('backspace_btn')?.addEventListener('click', function() {
    // オークション終了時は入力を無視
    if (this.disabled) return;
    
    currentAmount = Math.floor(currentAmount / 10);
    updateAmountDisplay();
  });
  
  
  // 入札ボタン
  document.getElementById('submit_btn')?.addEventListener('click', function() {
    // オークション終了時は入札を完全にブロック
    if (this.disabled || auctionEnded) {
      console.log('オークション終了のため入札できません');
      return;
    }
    
    if (currentAmount >= getMinBid() && !isDuplicateBid(currentAmount)) { // 最低価格以上かつ重複でない場合のみ
      console.log('入札開始:', currentAmount, '最低価格:', getMinBid());
      
      // 隠しフィールドに値を設定
      const bidInput = document.getElementById('bid_input');
      if (bidInput) {
        bidInput.value = currentAmount;
        console.log('隠しフィールドに設定:', bidInput.value);
        
        // フォームを送信
        const bidForm = document.getElementById('bid_form');
        if (bidForm) {
          // 再度オークション状態をチェック（二重チェック）
          const submitBtn = document.getElementById('submit_btn');
          if (submitBtn && (submitBtn.disabled || auctionEnded)) {
            console.log('オークション終了のため送信をキャンセル');
            return;
          }
          
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
              // ユーザーの入札履歴に追加
              userBidAmounts.push(currentAmount);
              currentAmount = 0;
              updateAmountDisplay();
              
              // 通知バッジを更新
              updateNotificationBadge();
              
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
      if (currentAmount < getMinBid()) {
        console.log('入札金額が不足:', currentAmount, '最低価格:', getMinBid());
      } else if (isDuplicateBid(currentAmount)) {
        console.log('同じ金額で既に入札済み:', currentAmount);
        alert('同じ金額で既に入札済みです');
      }
    }
  });
  
  // 初期表示の更新
  updateAmountDisplay();
  
  // ページ読み込み時にオークション状態をチェック
  checkAuctionStatus();
}

// ページ読み込み時とページ遷移時にイベントリスナーを設定
document.addEventListener('DOMContentLoaded', setupKeypadListeners);

// Turboのページ遷移時にもイベントリスナーを設定
document.addEventListener('turbo:load', setupKeypadListeners);

// オークションチャンネル（管理画面では接続しない）
let auctionSubscription = null;
if (!window.location.pathname.includes('/admin/') && !window.DISABLE_ACTIONCABLE) {
  // 現在のオークションIDを取得（URLから）
  const currentPath = window.location.pathname;
  const auctionIdMatch = currentPath.match(/\/auctions\/(\d+)/);
  const auctionId = auctionIdMatch ? auctionIdMatch[1] : 1; // デフォルトは1
  
  console.log('ActionCable接続開始 - Auction ID:', auctionId);
  auctionSubscription = consumer.subscriptions.create({ channel: "AuctionChannel", auction_id: auctionId }, {
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
    if (currentBidElement && data.current_bid !== undefined) {
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
    
    // 複数入札者数の更新
    const sameBidCountElement = document.getElementById("same_bid_count");
    const sameBidInfoElement = document.getElementById("same_bid_info");
    if (sameBidCountElement && data.same_bid_count !== undefined) {
      sameBidCountElement.innerText = data.same_bid_count;
      
      // 2人以上の場合のみ表示
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
        
        // 落札者かどうかを判定
        const currentUserId = document.querySelector('[data-user-id]')?.dataset.userId;
        const isWinner = data.winner_id && currentUserId && data.winner_id.toString() === currentUserId.toString();
        
        if (isWinner && data.hammer_price) {
          // 落札者の場合
          hammerPriceInfoElement.innerHTML = '<span class="hammer-price-text">🎉 おめでとうございます！落札されました！</span>';
          hammerPriceInfoElement.style.animation = 'hammerPulse 1s infinite';
          hammerPriceInfoElement.style.backgroundColor = '#d4edda';
          hammerPriceInfoElement.style.border = '2px solid #28a745';
          hammerPriceInfoElement.style.borderRadius = '8px';
          hammerPriceInfoElement.style.padding = '15px';
          hammerPriceInfoElement.style.margin = '10px 0';
          
          // 通知バッジを更新
          updateNotificationBadge();
          
          // 特別なアラート表示
          setTimeout(() => {
            alert('🎉 ' + data.message + ' 🎉');
          }, 500);
        } else {
          // 一般ユーザーの場合
          hammerPriceInfoElement.innerHTML = '<span class="hammer-price-text">🔨 オークション終了</span>';
          hammerPriceInfoElement.style.animation = '';
          hammerPriceInfoElement.style.backgroundColor = '';
          hammerPriceInfoElement.style.border = '';
          hammerPriceInfoElement.style.borderRadius = '';
          hammerPriceInfoElement.style.padding = '';
          hammerPriceInfoElement.style.margin = '';
        }
        
        // 入札フォーム全体を無効化
        disableBidForm();
      } else {
        hammerPriceInfoElement.style.display = "none";
        // 入札フォームを有効化
        enableBidForm();
      }
    }
    
    // 最低入札価格の更新
    const minBidElement = document.getElementById("min_bid");
    if (minBidElement) {
      const newMinBid = parseInt(data.current_bid); // 同じ金額でも入札可能
      minBidElement.innerText = `JPY ${newMinBid.toLocaleString()}`;
    }
    
    // 入力フィールドのmin属性の更新
    const bidInputElement = document.getElementById("bid_input");
    if (bidInputElement) {
      const newMinBid = parseInt(data.current_bid); // 同じ金額でも入札可能
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
    
    // 効果音の再生はモニター画面専用のため削除
    // 参加者画面では音を鳴らさない
    
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
    
    // オークション切り替えの処理
    if (data.auction_switch) {
      console.log('オークション切り替え通知を受信:', data);
      console.log('メッセージ:', data.message);
      console.log('新しいオークションURL:', data.new_auction_url);
      
      // 自動的に新しいオークションページに移動
      console.log('自動的に新しいオークションに移動します。');
      window.location.href = data.new_auction_url;
    }
  }
  });
} else {
  console.log('管理画面のため、ActionCable接続をスキップします');
}

// ユーザーチャンネルは使用しない（オークションチャンネルで統合処理）
}