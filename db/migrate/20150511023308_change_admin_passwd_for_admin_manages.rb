class ChangeAdminPasswdForAdminManages < ActiveRecord::Migration
  def change
  	  change_column :admin_manages,:admin_passwd,:string,:limit=>50
  end
end
