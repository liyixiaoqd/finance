class AddIsRateAmountFieldForOnlinePay < ActiveRecord::Migration
  def change
  	  	add_column :online_pays,:rate_amount,:decimal,:precision=>10,:scale=>2

  end
end
