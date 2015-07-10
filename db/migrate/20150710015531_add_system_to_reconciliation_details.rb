class AddSystemToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :reconciliation_details, :system, :string,:limit=>20
    add_column :reconciliation_details, :order_no, :string,:limit=>50
  end
end
