class AddCountryToReconciliationDetails < ActiveRecord::Migration
  def change
    add_column :reconciliation_details, :country, :string,:limit=>20
  end
end
