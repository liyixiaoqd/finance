class ModifyOrderNoToTables < ActiveRecord::Migration
  def change
  	change_column :online_pays,:order_no,:string,:limit=>1000
  	change_column :online_pays,:trade_no,:string,:limit=>1000
  	change_column :online_pays,:reconciliation_id,:string,:limit=>1000
  	change_column :reconciliation_details,:order_no,:string,:limit=>1000
  	change_column :reconciliation_details,:transactionid,:string,:limit=>1000
  	change_column :order_no_to_trade_nos,:order_no,:string,:limit=>1000
  	change_column :order_no_to_trade_nos,:trade_no,:string,:limit=>1000
  end
end
