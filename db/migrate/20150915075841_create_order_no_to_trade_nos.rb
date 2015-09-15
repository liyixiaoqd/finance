class CreateOrderNoToTradeNos < ActiveRecord::Migration
  def change
    create_table :order_no_to_trade_nos do |t|
      t.string :payway,    :limit=>20,:null=>false
      t.string :paytype,    :limit=>20,:default=>""
      t.string :trade_no
      t.string :order_no, :limit=>50,:null=>false

      t.timestamps
    end

    add_index :order_no_to_trade_nos,[:payway,:paytype,:trade_no],:name=>"index_order_no_to_trade_nos_1"
  end
end
