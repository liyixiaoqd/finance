class AddColumnToFinanceWater < ActiveRecord::Migration
  def change
    add_column :online_pays, :reconciliation_id, :string
  end
end
