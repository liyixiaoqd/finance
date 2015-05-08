# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150508081505) do

  create_table "admin_manages", force: true do |t|
    t.string   "admin_name",      limit: 10, null: false
    t.string   "admin_passwd",    limit: 10, null: false
    t.boolean  "is_active"
    t.string   "authority",       limit: 50, null: false
    t.string   "status",          limit: 10, null: false
    t.string   "role",            limit: 10, null: false
    t.datetime "last_login_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "basic_data", force: true do |t|
    t.string   "basic_type"
    t.string   "desc"
    t.string   "basic_sub_type"
    t.string   "sub_desc"
    t.string   "payway"
    t.string   "paytype"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "finance_waters", force: true do |t|
    t.string   "system",     limit: 20,                          null: false
    t.string   "channel",    limit: 20,                          null: false
    t.string   "userid",     limit: 50,                          null: false
    t.string   "symbol",     limit: 10,                          null: false
    t.decimal  "amount",                precision: 10, scale: 2
    t.decimal  "old_amount",            precision: 10, scale: 2
    t.decimal  "new_amount",            precision: 10, scale: 2
    t.string   "operator",   limit: 20
    t.string   "reason"
    t.datetime "operdate"
    t.integer  "user_id"
    t.string   "watertype",  limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "online_pays", force: true do |t|
    t.string   "system",              limit: 20,                            null: false
    t.string   "channel",             limit: 20,                            null: false
    t.string   "userid",              limit: 50,                            null: false
    t.string   "payway",              limit: 20,                            null: false
    t.string   "paytype",             limit: 20
    t.decimal  "amount",                           precision: 10, scale: 2, null: false
    t.string   "currency",            limit: 20
    t.string   "order_no",            limit: 50,                            null: false
    t.string   "success_url",         limit: 500
    t.string   "notification_url",    limit: 500
    t.string   "notification_email",  limit: 50
    t.string   "abort_url"
    t.string   "timeout_url"
    t.string   "ip",                  limit: 20
    t.string   "description"
    t.string   "country",             limit: 20
    t.decimal  "quantity",                         precision: 10, scale: 2
    t.string   "logistics_name"
    t.integer  "user_id"
    t.string   "status",              limit: 20,                            null: false
    t.string   "callback_status",     limit: 50
    t.string   "reason",              limit: 1000
    t.string   "redirect_url",        limit: 800
    t.string   "trade_no"
    t.boolean  "is_credit"
    t.string   "credit_pay_id",       limit: 50
    t.string   "credit_brand",        limit: 20
    t.string   "credit_number",       limit: 50
    t.string   "credit_verification", limit: 20
    t.string   "credit_month",        limit: 20
    t.string   "credit_year",         limit: 20
    t.string   "credit_first_name"
    t.string   "credit_last_name"
    t.string   "other_params"
    t.string   "remote_host"
    t.string   "remote_ip",           limit: 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reconciliation_id"
  end

  create_table "reconciliation_details", force: true do |t|
    t.string   "paytype",                 limit: 20
    t.string   "payway",                  limit: 20,                           null: false
    t.string   "batch_id",                limit: 20,                           null: false
    t.date     "transaction_date",                                             null: false
    t.datetime "timestamp"
    t.string   "timezone",                limit: 20
    t.string   "transaction_type",        limit: 100
    t.string   "email",                   limit: 50
    t.string   "name"
    t.string   "transactionid",                                                null: false
    t.string   "transaction_status",      limit: 20,                           null: false
    t.string   "online_pay_status",       limit: 20
    t.decimal  "amt",                                 precision: 10, scale: 2
    t.string   "currencycode",            limit: 20
    t.decimal  "feeamt",                              precision: 10, scale: 2
    t.decimal  "netamt",                              precision: 10, scale: 2
    t.string   "reconciliation_flag",     limit: 1
    t.string   "reconciliation_describe"
    t.integer  "online_pay_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "system",     limit: 20,                                        null: false
    t.string   "channel",    limit: 20,                                        null: false
    t.string   "userid",     limit: 50,                                        null: false
    t.string   "username",   limit: 50,                                        null: false
    t.string   "email",      limit: 50
    t.decimal  "e_cash",                precision: 10, scale: 2, default: 0.0
    t.decimal  "score",                 precision: 10, scale: 2, default: 0.0
    t.string   "operator",   limit: 20
    t.datetime "operdate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
