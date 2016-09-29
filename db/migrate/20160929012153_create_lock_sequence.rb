class CreateLockSequence < ActiveRecord::Migration
  def change
    create_table :lock_sequences do |t|
    	t.string :maintype
    	t.string :subtype
    	t.integer :seq
    	t.string :str_format
    	t.string :status

    	t.timestamps
    end
  end
end
