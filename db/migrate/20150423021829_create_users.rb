class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :system,    :limit=>20,:null=>false
      t.string :channel,   :limit=>20,:null=>false
      t.string :userid,    :limit=>50,:null=>false
      t.string :username,  :limit=>50,:null=>false
      t.string :email,     :limit=>50
      t.decimal :e_cash,  :precision=>10,:scale=>2,:default=>0.0
      t.decimal :score,    :precision=>10,:scale=>2,:default=>0.0
      t.string :operator,  :limit=>20
      t.datetime :operdate
      t.timestamps
    end
  end
end
