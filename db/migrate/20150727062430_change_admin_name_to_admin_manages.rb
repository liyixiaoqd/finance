class ChangeAdminNameToAdminManages < ActiveRecord::Migration
  def change
  	change_column :admin_manages, :admin_name, :string,:limit=>20
  end
end
