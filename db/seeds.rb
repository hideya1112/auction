# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.create!(name: genre_name)
#   end

# 商品データの作成
items = [
  { name: "アンティーク時計", description: "1920年代の貴重な懐中時計", starting_price: 50000 },
  { name: "絵画作品", description: "現代アートの傑作", starting_price: 100000 },
  { name: "骨董品", description: "江戸時代の陶器", starting_price: 30000 },
  { name: "宝石", description: "天然ダイヤモンド", starting_price: 200000 },
  { name: "古書", description: "明治時代の貴重な書籍", starting_price: 15000 }
]

items.each do |item_data|
  Item.find_or_create_by!(name: item_data[:name]) do |item|
    item.description = item_data[:description]
    item.starting_price = item_data[:starting_price]
  end
end

# ユーザーデータの作成
users = [
  { user_id: "HDY111", name: "田中太郎" },
  { user_id: "HDY222", name: "佐藤花子" },
  { user_id: "HDY333", name: "鈴木一郎" },
  { user_id: "HDY444", name: "高橋美咲" },
  { user_id: "HDY555", name: "渡辺健太" }
]

users.each do |user_data|
  User.find_or_create_by!(user_id: user_data[:user_id]) do |user|
    user.name = user_data[:name]
  end
end

# オークションデータの作成（最初の商品で）
first_item = Item.first
if first_item
  auction = Auction.find_or_create_by!(item: first_item) do |a|
    a.current_bid = a.item.starting_price
    a.status = 'active'
  end
  
  # 初期の入札ログを作成（開始価格での入札）
  if auction.bid_logs.empty?
    first_user = User.first
    if first_user
      auction.bid_logs.create!(
        user_id: first_user.id,
        bid_amount: auction.current_bid,
        bid_time: Time.current
      )
    end
  end
end