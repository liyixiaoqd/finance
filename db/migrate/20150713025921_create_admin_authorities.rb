class CreateAdminAuthorities < ActiveRecord::Migration
  def change
    create_table :admin_authorities do |t|
      t.integer :admin_manage_id,:null=>false
      t.string :admin_name,:null=>false
      t.string :controller,:null=>false
      t.string :action,:null=>false
      t.integer :no,:null=>false
      t.string :describe,:null=>false
      t.boolean :status,:null=>false
      t.timestamps
    end
  end
end
