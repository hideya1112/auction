namespace :auction do
  desc "Set auction 1 to active and all others to inactive"
  task set_status: :environment do
    puts "=== オークションステータスの更新を開始 ==="
    
    # 全てのオークションを非アクティブにする
    inactive_count = Auction.update_all(status: 'inactive')
    puts "全オークション #{inactive_count} 件を非アクティブにしました"
    
    # オークション1だけをアクティブにする
    auction_1 = Auction.find_by(id: 1)
    if auction_1
      auction_1.update!(status: 'active')
      puts "オークション 1 をアクティブにしました"
    else
      puts "オークション 1 が見つかりません"
    end
    
    puts "=== オークションステータスの更新が完了しました ==="
    puts "アクティブなオークション数: #{Auction.active.count}"
    puts "非アクティブなオークション数: #{Auction.inactive.count}"
    puts "ハンマープライス済みオークション数: #{Auction.hammered.count}"
  end
end
