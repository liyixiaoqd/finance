class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.string :system,    :limit=>20,:null=>false
      t.string :userid,    :limit=>50,:null=>false
      t.string :invoice_no, :limit=>50,:null=>false
      t.text :water_no 
      t.decimal :amount,:precision=>10,:scale=>2
      t.string :description
      t.string :operdate, :limit=>10,:null=>false
      t.string :begdate, :limit=>10,:null=>false
      t.string :enddate, :limit=>10,:null=>false

      t.integer :user_id
      t.timestamps
    end
  end
end
