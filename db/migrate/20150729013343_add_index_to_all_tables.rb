class AddIndexToAllTables < ActiveRecord::Migration
  def change
  	add_index :admin_manages,[:admin_name],:name=>"index_admin_manages_1"
  	add_index :admin_authorities,[:admin_name,:controller,:action],:name=>"index_admin_authorities_1"
  	add_index :access_authorities,[:controller,:action],:name=>"index_access_authorities_1"
  	add_index :access_authorities,[:access_level,:is_interface,:is_sign_in],:name=>"index_access_authorities_2"
  	add_index :users,[:system,:userid],:name=>"index_users_1"
  	add_index :users,[:email],:name=>"index_users_2"
  	add_index :users,[:username],:name=>"index_users_3"
  	add_index :online_pays,[:payway,:paytype,:order_no],:name=>"index_online_pays_1"
  	add_index :online_pays,[:payway,:paytype,:trade_no],:name=>"index_online_pays_2"
  	add_index :online_pays,[:created_at],:name=>"index_online_pays_3"
  	add_index :online_pays,[:status],:name=>"index_online_pays_4"
  	add_index :basic_data,[:basic_type,:basic_sub_type,:payway,:paytype],:name=>'index_basic_data_1'
  	add_index :reconciliation_details,[:payway,:paytype,:transactionid],:name=>"index_reconciliation_details_1"
  	add_index :reconciliation_details,[:confirm_flag,:reconciliation_flag],:name=>"index_reconciliation_details_2"
  	add_index :reconciliation_details,[:timestamp],:name=>"index_reconciliation_details_3"
  	add_index :finance_waters,[:channel,:operdate],:name=>"index_finance_waters_1"

  	add_index :admin_authorities,[:admin_manage_id],:name=>"index_foreign_admin_authorities_1"
  	add_index :finance_waters,[:user_id],:name=>"index_foreign_finance_waters_1"
  	add_index :online_pays,[:user_id],:name=>"index_foreign_online_pays_1"
  	add_index :reconciliation_details,[:online_pay_id],:name=>"index_foreign_reconciliation_details_1"
  end
end
