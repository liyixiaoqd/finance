class CreateCashCouponDetail < ActiveRecord::Migration
  def change
    create_table :cash_coupon_details do |t|
    	t.integer :cash_coupon_id,	:null=>false
    	t.integer :quantity,		:null=>false
    	t.string :order_no,			:null=>false
    	t.string :state,			:limit=>10,:null=>false
    	t.string :remark,			:limit=>100
    	t.datetime :use_time
    	t.datetime :cancel_time
    	t.datetime :frozen_time

    	t.timestamps
    end

    add_index :cash_coupon_details,[:order_no],:name=>"index_cash_coupon_details_1"
  end
end
