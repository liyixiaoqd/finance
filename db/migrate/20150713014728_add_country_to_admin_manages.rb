class AddCountryToAdminManages < ActiveRecord::Migration
  def change
    add_column :admin_manages, :country, :string,    :limit=>60
  end
end
