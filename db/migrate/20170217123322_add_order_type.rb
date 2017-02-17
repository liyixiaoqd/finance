class AddOrderType < ActiveRecord::Migration
  def change
  	add_column :online_pays, :order_type, :string,default: "parcel"
  	add_column :reconciliation_details, :order_type, :string
  end
end
