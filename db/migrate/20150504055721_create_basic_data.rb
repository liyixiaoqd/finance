class CreateBasicData < ActiveRecord::Migration
  def change
    create_table :basic_data do |t|
      t.string :basic_type
      t.string :desc
      t.string :basic_sub_type
      t.string :sub_desc
      t.string :payway
      t.string :paytype
      t.string :value

      t.timestamps
    end
  end
end
