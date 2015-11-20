class AddThirdnoToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :online_pays, :thirdno, :string
    add_column :online_pays, :credit_email, :string,:limit=>128
  end
end
