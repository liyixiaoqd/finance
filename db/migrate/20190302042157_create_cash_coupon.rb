class CreateCashCoupon < ActiveRecord::Migration
  def change
    create_table :cash_coupons do |t|
    	t.string :system,    	:limit=>20,:null=>false
    	t.string :userid,		:limit=>50,:null=>false
    	t.string :order_no,		:null=>false
    	t.integer :user_id,		:null=>false
    	t.date :end_date,	 	:null=>false
    	t.integer :quantity,	:null=>false
    	t.integer :av_quantity, :null=>false
    	t.integer :fr_quantity,	:null=>false,:default=>0
        t.decimal :cny_amount,  :null=>false,:precision=>6,:scale=>2
        t.decimal :eur_amount,  :null=>false,:precision=>6,:scale=>2

    	t.timestamps
    end

    add_index :cash_coupons,[:system, :userid, :order_no],:name=>"index_cash_coupons_1"
  end
end
