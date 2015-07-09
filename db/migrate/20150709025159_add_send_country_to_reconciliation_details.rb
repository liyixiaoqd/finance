class AddSendCountryToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :reconciliation_details, :send_country, :string,:limit=>20
  end
end
