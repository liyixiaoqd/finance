class CreateScoreWaters < ActiveRecord::Migration
  def change
    create_table :finance_waters do |t|
      t.string :system,    :limit=>20,:null=>false
      t.string :channel,   :limit=>20,:null=>false
      t.string :userid,      :limit=>50,:null=>false
      t.string :symbol,    :limit=>10,:null=>false
      t.decimal :amount,:precision=>10,:scale=>2
      t.decimal :old_amount,:precision=>10,:scale=>2
      t.decimal :new_amount,:precision=>10,:scale=>2
      t.string :operator,:limit=>20
      t.string :reason
      t.datetime :operdate
      t.integer :user_id
      t.string :watertype,:limit=>10

      t.timestamps
    end
  end
end
