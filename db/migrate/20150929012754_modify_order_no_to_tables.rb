class ModifyOrderNoToTables < ActiveRecord::Migration
  def change
  	change_column :online_pays,:order_no,:string,:limit=>500
  	change_column :reconciliation_details,:order_no,:string,:limit=>500
  	change_column :order_no_to_trade_nos,:order_no,:string,:limit=>500
  end
end
