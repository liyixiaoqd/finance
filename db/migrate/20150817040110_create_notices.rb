class CreateNotices < ActiveRecord::Migration
  def change
    create_table :notices do |t|
      t.string :title
      t.string :content
      t.string :flag,:limit=>1
      t.string :notice_type,:limit=>20
      t.datetime :opertime
      t.string :proc_user,:limit=>20
      t.datetime :proc_time
      t.integer :finance_water_id

      t.timestamps
    end
  end
end
