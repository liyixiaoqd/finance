class CreateAccessAuthorities < ActiveRecord::Migration
  def change
    create_table :access_authorities do |t|
      t.string :controller, :limit => 50
      t.string :action, :limit => 30
      t.boolean :is_sign_in
      t.boolean :is_interface
      t.integer :access_level, :limit => 2
      t.string :describe


      t.timestamps
    end
  end
end
