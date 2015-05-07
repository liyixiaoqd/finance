class CreateOnlinePays < ActiveRecord::Migration
  def change
    create_table :online_pays do |t|
      t.string :system,    :limit=>20,:null=>false
      t.string :channel,    :limit=>20,:null=>false
      t.string :userid, :limit=>50,:null=>false
      t.string :payway,    :limit=>20,:null=>false
      t.string :paytype,    :limit=>20,:default=>""
      t.decimal :amount,:precision=>10,:scale=>2,:null=>false
      t.string :currency,    :limit=>20
      t.string :order_no, :limit=>50,:null=>false
      t.string :success_url, :limit=>500
      t.string :notification_url, :limit=>500
      t.string :notification_email,    :limit=>50
      t.string :abort_url
      t.string :timeout_url
      t.string :ip,    :limit=>20
      t.string :description
      t.string :country,    :limit=>20
      t.decimal :quantity,:precision=>10,:scale=>2
      t.string :logistics_name
      t.integer :user_id
      t.string :status,    :limit=>20,:null=>false
      t.string :callback_status,    :limit=>50
      t.string :reason, :limit=>1000
      t.string :redirect_url, :limit=>800
      t.string :trade_no
      t.boolean :is_credit
      t.string :credit_pay_id,    :limit=>50
      t.string :credit_brand,    :limit=>20
      t.string :credit_number,    :limit=>50
      t.string :credit_verification,    :limit=>20
      t.string :credit_month,    :limit=>20
      t.string :credit_year,    :limit=>20
      t.string :credit_first_name
      t.string :credit_last_name
      t.string :other_params
      t.string :remote_host
      t.string :remote_ip,    :limit=>20

      t.timestamps
    end
  end
end
