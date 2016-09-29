class CreateQyIdMatch < ActiveRecord::Migration
  def change
    create_table :qy_id_matches do |t|
    	t.string :old_id
    	t.string :old_table
    	t.integer :new_id
    	t.string :new_table
    end
    add_index :qy_id_matches,[:old_id,:old_table]
    add_index :qy_id_matches,[:new_id,:new_table]
  end
end
