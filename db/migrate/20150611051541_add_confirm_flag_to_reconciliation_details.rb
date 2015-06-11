class AddConfirmFlagToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :reconciliation_details, :confirm_flag, :string,:limit=>1,:default=>"0"
    add_column :reconciliation_details, :confirm_date, :timestamp
  end
end
