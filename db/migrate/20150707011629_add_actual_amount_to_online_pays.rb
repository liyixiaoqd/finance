class AddActualAmountToOnlinePays < ActiveRecord::Migration
  def change
    add_column :online_pays, :actual_amount, :decimal,  :precision=>10,:scale=>2,:default=>0.0
  end
end
