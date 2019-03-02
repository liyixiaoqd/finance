class AddCashCouponToOnlinePay < ActiveRecord::Migration
  def change
  	add_column :online_pays, :cash_coupon, :boolean,default: false
  end
end
