class AddInvoiceDateToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :reconciliation_details, :invoice_date, :timestamp
  end
end
