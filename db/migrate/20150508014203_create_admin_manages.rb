class CreateAdminManages < ActiveRecord::Migration
  def change
    create_table :admin_manages do |t|
      t.string :admin_name,:limit=>10,:null=>false
      t.string :admin_passwd,:limit=>10,:null=>false
      t.boolean :is_active
      t.string :authority,:limit=>50,:null=>false
      t.string :status  ,:limit=>10,:null=>false
      t.string :role,:limit=>10,:null=>false
      t.datetime :last_login_time
      
      t.timestamps
    end
  end
end
