class AddSendCountryToOnlinePays < ActiveRecord::Migration
  def change
    add_column :online_pays, :send_country, :string,:limit=>20
  end
end
