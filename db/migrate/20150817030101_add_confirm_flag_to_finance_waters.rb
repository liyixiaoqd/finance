class AddConfirmFlagToFinanceWaters < ActiveRecord::Migration
  def change
    add_column :finance_waters, :confirm_flag, :string,:limit=>1,:default=>"1"
  end
end
