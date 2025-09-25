// 管理画面専用のJavaScript
console.log('管理画面専用JavaScriptが読み込まれました');

// ActionCableを完全に無効化
if (typeof window !== 'undefined') {
  // ActionCable関連のオブジェクトを完全にクリア
  window.Consumer = null;
  window.ActionCable = null;
  
  // ActionCableの初期化を防ぐ
  if (window.ActionCable) {
    delete window.ActionCable;
  }
  if (window.Consumer) {
    delete window.Consumer;
  }
  
  // ActionCableの初期化を防ぐためのフラグを設定
  window.DISABLE_ACTIONCABLE = true;
  
  // ActionCableの初期化を防ぐためのモック関数を設定
  window.ActionCable = {
    createConsumer: function() {
      console.log('ActionCable.createConsumer is disabled in admin');
      return null;
    }
  };
  
  // WebSocketの初期化も防ぐ
  if (window.WebSocket) {
    const originalWebSocket = window.WebSocket;
    window.WebSocket = function() {
      console.log('WebSocket is disabled in admin');
      return null;
    };
  }
  
  // ActionCableの初期化を防ぐためのモックConsumerを設定
  window.Consumer = {
    subscriptions: {
      create: function() {
        console.log('Consumer.subscriptions.create is disabled in admin');
        return null;
      }
    }
  };
  
  // ActionCableの初期化を防ぐためのモックSubscriptionを設定
  window.Subscription = function() {
    console.log('Subscription is disabled in admin');
    return null;
  };
  
  // ActionCableの初期化を防ぐためのモックChannelを設定
  window.Channel = function() {
    console.log('Channel is disabled in admin');
    return null;
  };
  
  // ActionCableの初期化を防ぐためのモックConnectionを設定
  window.Connection = function() {
    console.log('Connection is disabled in admin');
    return null;
  };
  
  // ActionCableの初期化を防ぐためのモックCableを設定
  window.Cable = function() {
    console.log('Cable is disabled in admin');
    return null;
  };
  
  // ActionCableの初期化を防ぐためのモックCableを設定
  window.Cable = function() {
    console.log('Cable is disabled in admin');
    return null;
  };
  
  // ActionCableの初期化を防ぐためのモックCableを設定
  window.Cable = function() {
    console.log('Cable is disabled in admin');
    return null;
  };
}

console.log('管理画面でのActionCable無効化が完了しました');
