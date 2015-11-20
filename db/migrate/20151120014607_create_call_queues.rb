class CreateCallQueues < ActiveRecord::Migration
  def change
    create_table :call_queues do |t|
      t.string :callback_interface
      t.string :reference_id
      t.string :status
      t.string :run_batch
      t.datetime :last_callback_time
      t.string :last_callback_result
      t.integer :try_amount
      t.integer :tried_amount
      t.string :start_call_time

      t.timestamps
    end

    add_index :call_queues,[:callback_interface,:status,:start_call_time],:name=>"index_call_queues_1"
    add_index :call_queues,[:reference_id],:name=>"index_call_queues_2"
  end
end
