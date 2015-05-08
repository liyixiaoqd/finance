class ChangeTransactionTypeForReconciliationDetail < ActiveRecord::Migration
  def change
  	change_column :reconciliation_details,:transaction_type,:string,:limit=>100
  end
end
