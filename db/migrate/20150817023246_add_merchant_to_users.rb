class AddMerchantToUsers < ActiveRecord::Migration
  def change
     add_column :users, :user_type, :string,:limit=>10,:default=>'personal'
     add_column :users, :address, :string
     add_column :users, :vat_no, :string,:limit=>30
     add_column :users, :pay_type, :string,:limit=>10
     add_column :users, :pay_limit, :decimal,  :precision=>10,:scale=>2
  end
end
