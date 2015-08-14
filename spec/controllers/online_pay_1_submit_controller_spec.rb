require 'rails_helper'

describe OnlinePayController do
	fixtures :users

	describe "clean online_pay data:" do
		it "clean" do
			OnlinePay.where("order_no like ?","SPEC%").delete_all

			expect(OnlinePay.where("order_no like ?","SPEC%").count).to eq 0

			ReconciliationDetail.where("order_no like ?","SPEC%").delete_all
		end
	end

	describe "online_pay call:" do
		it "post submit" do
			request.session[:admin]="admin"
			post :submit,init_paypal_submit_params()

			expect(response.body).to match "redirect_url"

			op=OnlinePay.where(payway: 'paypal').last
			expect(op).not_to eq nil
			expect(op['status']).to eq("submit")
			expect(op['order_no']).to eq(@order_no)
		end
	end

	describe "alipay_oversea call:" do
		it "post submit" do
			alipay_oversea_trade_no="mypost4u_alipay_oversea_20150519_002"
			request.session[:admin]="admin"
			post :submit,init_alipay_oversea_submit_params()

			expect(response.body).to match "redirect_url"

			op=OnlinePay.where(payway: 'alipay',paytype: 'oversea').last
			expect(op).not_to eq nil
			expect(op['status']).to eq("submit")
			expect(op['order_no']).to eq(@order_no)

			op.trade_no=alipay_oversea_trade_no
			op.save!()
		end
	end	

	describe "alipay_transaction call:" do
		it "post submit" do
			alipay_transaction_trade_no="mypost4u_alipay_transaction_20150519_000"
			request.session[:admin]="admin"
			post :submit,init_alipay_transaction_submit_params()

			expect(response.body).to match "redirect_url"

			op=OnlinePay.where(payway: 'alipay',paytype: 'transaction').last
			expect(op).not_to eq nil
			expect(op['status']).to eq("submit")
			expect(op['order_no']).to eq(@order_no)
			
			op.trade_no=alipay_transaction_trade_no
			op.save!()
		end
	end	

	describe "sofort call:" do
		it "post submit" do
			sofort_trade_no="84221-175012-5551946E-46EF"
			request.session[:admin]="admin"
			post :submit,init_sofort_submit_params()

			expect(response.body).to match "redirect_url"

			op=OnlinePay.where(payway: 'sofort').last
			expect(op).not_to eq nil
			expect(op['status']).to eq("submit")
			expect(op['order_no']).to eq(@order_no)

			op['trade_no']=sofort_trade_no
			op.save!()
		end
	end	



	let!(:init_params) do
		if @CALL_HOST.blank?
			@CALL_HOST=Settings.simulation.call_host
			@order_no="SPEC"+Time.now.strftime("%Y%m%d%H%M%S")+"001"
			@amount= (rand(0.99)*100).round(2)


			#OnlinePay.where(order_no:  @order_no).delete_all
			@init_online_pay_params={
				'system'=>'',
				'payway'=>'',
				'paytype'=>'',
				'userid'=>'',
				'amount'=>'',
				'currency'=>'',
				'order_no'=>'',
				'success_url'=>'',
				'notification_url'=>'',
				'notification_email'=>'',
				'abort_url'=>'',
				'timeout_url'=>'',
				'ip'=>'',
				'description'=>'',
				'country'=>'',
				'quantity'=>'',
				'logistics_name'=>'',
				'userid'=>users(:user_one)['userid'],
				'send_country'=>'nl'
			}
		end
	end

	let(:init_paypal_submit_params) do
		paypal_submit_params={
			'system'=>'mypost4u',
			'payway'=>'paypal',
			'paytype'=>'',
			'amount'=>@amount,
			'currency'=>'EUR',
			'order_no'=>@order_no,
			'description'=>"TESTMODE:#{@order_no}",
			'ip'=>'127.0.0.1',
			'success_url'=>"#{@CALL_HOST}/simulation/callback_return",
			'abort_url'=>"#{@CALL_HOST}/simulation/callback_return",
			'notification_url'=>"#{@CALL_HOST}/simulation/callback_notify",
			'country'=>'de',
			'channel'=>'web'
		}

		@init_online_pay_params.merge!(paypal_submit_params)
	end	

	let(:init_sofort_submit_params) do
		sofort_submit_params={
			'system'=>'mypost4u',
			'payway'=>'sofort',
			'paytype'=>'',
			'amount'=>@amount,
			'currency'=>'EUR',
			'order_no'=>@order_no,
			'success_url'=> "#{@CALL_HOST}/simulation/callback_return",
			'abort_url'=> "#{@CALL_HOST}/simulation/callback_return",
			'notification_url'=>"#{@CALL_HOST}/simulation/callback_notify",
			'timeout_url'=> "#{@CALL_HOST}/simulation/callback_return",
			'country'=>'de',
			'channel'=>'web'
		}		
		@init_online_pay_params.merge!(sofort_submit_params)
	end

	let(:init_alipay_oversea_submit_params) do
		alipay_oversea_submit_params={
			'system'=>'mypost4u',
			'payway'=>'alipay',
			'paytype'=>'oversea',
			'amount'=>@amount,
			'currency'=>'EUR',
			'order_no'=>@order_no,
			'description'=>"TESTMODE:#{@order_no}",
			'success_url'=>"#{@CALL_HOST}/simulation/callback_return",
			'notification_url'=>"#{@CALL_HOST}/simulation/callback_notify",
			'channel'=>'web'
		}		
		@init_online_pay_params.merge!(alipay_oversea_submit_params)
	end

	let(:init_alipay_transaction_submit_params) do
		alipay_transaction_submit_params={
			'system'=>'mypost4u',
			'payway'=>'alipay',
			'paytype'=>'transaction',
			'amount'=>@amount,
			'order_no'=>@order_no,
			'logistics_name'=>'logistics_name',
			'description'=>"测试交易:订单号#{@order_no}的寄送包裹费用",
			'success_url'=>"#{@CALL_HOST}/simulation/callback_return",
			'notification_url'=>"#{@CALL_HOST}/simulation/callback_notify",
			'quantity'=>1,
			'channel'=>'web'
		}		
		@init_online_pay_params.merge!(alipay_transaction_submit_params)
	end
end