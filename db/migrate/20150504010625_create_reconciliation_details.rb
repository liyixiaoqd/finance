class CreateReconciliationDetails < ActiveRecord::Migration
  def change
    create_table :reconciliation_details do |t|
      t.string :paytype,    :limit=>20
      t.string :payway,    :limit=>20,:null=>false
      t.string :batch_id,   :limit=>20,:null=>false
      t.date :transaction_date,:null=>false
      t.datetime :timestamp
      t.string :timezone,    :limit=>20
      t.string :transaction_type,    :limit=>20
      t.string :email,     :limit=>50
      t.string :name
      t.string :transactionid,:null=>false
      t.string :transaction_status,    :limit=>20,:null=>false
      t.string :online_pay_status,    :limit=>20
      t.decimal :amt,:precision=>10,:scale=>2
      t.string :currencycode,    :limit=>20
      t.decimal :feeamt,:precision=>10,:scale=>2
      t.decimal :netamt,:precision=>10,:scale=>2
      t.string :reconciliation_flag, :limit=>1
      t.string :reconciliation_describe
      t.integer :online_pay_id

      t.timestamps
    end
  end
end
