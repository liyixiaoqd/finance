class OnlinePayTrackInfo < ActiveRecord::Migration
  def change
      create_table :online_pay_track_infos do |t|
    	t.string :order_no,:null=>false
    	t.string :ishpmt_nums
    	t.string :tracking_urls
    	t.integer :online_pay_id,:null=>false

    	t.timestamps
    end
    add_index :online_pay_track_infos,:order_no
  end
end
