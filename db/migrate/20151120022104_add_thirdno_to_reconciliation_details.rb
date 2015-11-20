class AddThirdnoToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :reconciliation_details, :thirdno, :string
    add_column :online_pays, :credit_email, :string,:limit=>128
  end
end
