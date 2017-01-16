class ExchangeRate < ActiveRecord::Migration
  def change
  	create_table :exchange_rates do |t|
		t.string :currency
		t.decimal :rate,:precision=>8,:scale=>4
		t.date :rate_date
		t.datetime :rate_datetime
		t.integer :flag,default: 0
		t.string :remark

		t.timestamps
	end

	add_index :exchange_rates,[:currency,:rate_date],:name=>"index_exchange_rates_1"
  end
end
