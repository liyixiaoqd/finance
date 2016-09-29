class AddInvoiceNoToReconciliationDetails < ActiveRecord::Migration
  def change
  	add_column :reconciliation_details, :invoice_no, :string
  end
end
