class ChangeLengthToIspmtNums < ActiveRecord::Migration
  def change
  	change_column :online_pay_track_infos,:ishpmt_nums,:string,:limit=>850
  	change_column :online_pay_track_infos,:tracking_urls,:string,:limit=>850
  end
end
