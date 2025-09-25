# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_25_093232) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "auctions", force: :cascade do |t|
    t.bigint "current_bid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "item_id", default: 1, null: false
    t.string "status", default: "active", null: false
    t.index ["item_id"], name: "index_auctions_on_item_id"
    t.index ["status"], name: "index_auctions_on_status"
  end

  create_table "bid_logs", force: :cascade do |t|
    t.integer "auction_id", null: false
    t.integer "user_id", null: false
    t.bigint "bid_amount", null: false
    t.datetime "bid_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id", "bid_amount"], name: "index_bid_logs_on_auction_id_and_bid_amount"
    t.index ["auction_id"], name: "index_bid_logs_on_auction_id"
    t.index ["bid_time"], name: "index_bid_logs_on_bid_time"
    t.index ["user_id"], name: "index_bid_logs_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "starting_price", null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_items_on_name"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "auction_id", null: false
    t.text "message"
    t.string "notification_type"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id"], name: "index_notifications_on_auction_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name"
    t.index ["user_id"], name: "index_users_on_user_id", unique: true
  end

  add_foreign_key "notifications", "auctions"
  add_foreign_key "notifications", "users"
end
