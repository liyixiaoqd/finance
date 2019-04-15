class ChangeLengthToOnlinePaysOtherParams < ActiveRecord::Migration
  def change
  	change_column :online_pays,:other_params,:string,:limit=>700
  end
end
