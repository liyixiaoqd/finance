require 'rails_helper'

describe OnlinePayCallbackController do
	let!(:set_stub!){
		allow_any_instance_of(OnlinePay).to receive(:method_url_response_code).and_return("200")
		allow_any_instance_of(AlipayDetailable).to receive(:notify_verify?).and_return(true)
		# RSpec::Mocks.with_temporary_scop do
		# 	# allow(OnlinePay).to receive(:method_url_response_code){ "200" }
		# 	allow_any_instance_of(OnlinePay).to receive(:method_url_response_code).and_return("200")
		# 	allow_any_instance_of(AlipayDetailable).to receive(:notify_verify?).and_return(true)
		# end
	}

	describe "online_pay_callback call:" do
		it "get paypal_abort" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'paypal',status: 'submit').last
			expect(op).not_to eq nil
			rollback_status=op.status
			rollback_callback_status=op.callback_status

			get :paypal_abort,:token=>op['trade_no']
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['abort_url'])
			expect(op['status']).to eq("cancel_notify")

			op.status=rollback_status
			op.callback_status=rollback_callback_status
			op.save!()
		end

		it "get paypal_return" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'paypal',status: 'submit').last
			expect(op).not_to eq nil

			payid="5UTQRPSVZEPD6"

			get :paypal_return,:token=>op['trade_no'],:PayerID=>payid
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['success_url'])
			expect(response.body).to match (/sign/)
			expect(op['status']).to eq("failure_credit")

			if op.credit_pay_id.blank?
				op.credit_pay_id=payid
				op.save!()
			end
		end

		it "get sofort_abort" do
			sofort_trade_no="84221-175012-5551946E-46EF"
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'sofort',status: 'submit').last
			expect(op).not_to eq nil
			rollback_status=op.status
			rollback_callback_status=op.callback_status
			
			get :sofort_abort,:system=>op.system,:order_no=>op.order_no
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['abort_url'])
			expect(op['status']).to eq("cancel_notify")

			op.status=rollback_status
			op.callback_status=rollback_callback_status
			op.save!()
		end

		it "get sofort_return" do
			sofort_trade_no="84221-175012-5551946E-46EF"
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'sofort',status: 'submit').last
			expect(op).not_to eq nil

			get :sofort_return,:system=>op.system,:order_no=>op.order_no
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['success_url'])
			expect(response.body).to match (/sign/)
		end

		it "post sofort_notify" do
			sofort_trade_no="84221-175012-5551946E-46EF"
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'sofort',status: 'submit').last
			expect(op).not_to eq nil

			post :sofort_notify,:status_notification=>{"transaction"=>sofort_trade_no, "time"=>"2015-05-12T07:50:14+02:00"}
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq ("success")
			expect(op['status']).to eq("failure_notify_third")
		end

		it "get alipay_oversea_return" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'alipay',paytype: 'oversea',status: 'submit').last
			expect(op).not_to eq nil

			get :alipay_oversea_return,alipay_oversea_return_params()
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['success_url'])
			expect(response.body).to match (/sign/)
		end

		it "post alipay_oversea_notify" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'alipay',paytype: 'oversea',status: 'submit').last
			expect(op).not_to eq nil

			post :alipay_oversea_notify,alipay_oversea_notify_params()
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq("success")
			expect(op['status']).to eq("failure_notify_third")
			expect(op['rate_amount']).not_to eq(op['amount'])
		end

		it "get alipay_transaction_retrun" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'alipay',paytype: 'transaction',status: 'submit').last
			expect(op).not_to eq nil

			get :alipay_transaction_return,alipay_transaction_return_params()
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['success_url'])
			expect(response.body).to match (/sign/)
		end

		it "get alipay_transaction_notify" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'alipay',paytype: 'transaction').last
			op.update_attributes!({'system'=>'mypost4u','callback_status'=>''}) if op.present?

			op=OnlinePay.where(payway: 'alipay',paytype: 'transaction',status: 'submit').last
			expect(op).not_to eq nil

			post :alipay_transaction_notify,alipay_transaction_notify_params_1()
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq("success")
			expect(op['status']).to eq("intermediate_notify")
			expect(op['callback_status']).to eq("WAIT_BUYER_PAY")

			post :alipay_transaction_notify,alipay_transaction_notify_params_3()
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq("failure")
			expect(op['status']).to eq("failure_notify")
			expect(op['reason']).to eq("TRADE_STATUS_NOT_AVAILD")
			expect(op['callback_status']).to eq("WAIT_BUYER_PAY")

			post :alipay_transaction_notify,alipay_transaction_notify_params_4()
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq("success")
			expect(op['status']).to eq("failure_notify_third")
			expect(op['callback_status']).to eq("WAIT_BUYER_CONFIRM_GOODS")

			post :alipay_transaction_notify,alipay_transaction_notify_params_5()
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq("success")
			expect(op['status']).to eq("failure_notify_third")
			expect(op['callback_status']).to eq("TRADE_FINISHED")


			post :alipay_transaction_notify,alipay_transaction_notify_params_2()
			op.reload
			expect(response.status).to eq(200)
			expect(response.body).to eq("success")
			expect(op['status']).to eq("failure_notify_third")
			expect(op['callback_status']).to eq("TRADE_FINISHED")
		end

		it "get alipay_transaction_notify use quaie" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'alipay',paytype: 'transaction').last
			op.update_attributes!({'system'=>'quaie','callback_status'=>'WAIT_SELLER_SEND_GOODS'})
			op.reconciliation_detail.delete if op.reconciliation_detail.present?

			expect(op).not_to eq nil
			expect{
				post :alipay_transaction_notify,alipay_transaction_notify_params_4()
			}.to change(FinanceWater,:count).by(1)
		end
	end

	let(:getseqId) do
		Time.now.strftime("%Y%m%d%H%M%S")
	end

	let(:alipay_oversea_return_params) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_oversea_20150519_002'").last

		{
			"sign"=>"8ac74f1c16cd3d8dcc25a7f10c0cc4ec", 
			"trade_no"=>"2015051900001000980052833147", 
			"total_fee"=>"0.01", 
			"sign_type"=>"MD5", 
			"out_trade_no"=>"#{op.system}_#{op.order_no}", 
			"trade_status"=>"TRADE_FINISHED", 
			"currency"=>"EUR"
		}
	end

	let(:alipay_oversea_notify_params) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_oversea_20150519_002'").last

		{
			"notify_id"=>"e0de91c150d106a5e409a477dc9d3a107g", 
			"notify_type"=>"trade_status_sync", 
			"sign"=>"a7a3ff52a4d87ee2017944576b4f681c", 
			"trade_no"=>"2015051900001000980052833147", 
			"total_fee"=>"0.01", 
			"out_trade_no"=>"#{op.system}_#{op.order_no}", 
			"currency"=>"EUR", 
			"notify_time"=>"2015-05-19 09:08:33", 
			"trade_status"=>"TRADE_FINISHED", 
			"sign_type"=>"MD5"
		}
	end

	let(:alipay_transaction_return_params) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_transaction_20150519_000'").last

		{
			"buyer_actions"=>"REFUND,CONFIRM_GOODS", 
			"buyer_email"=>"13764886276", 
			"buyer_id"=>"2088702362165983", 
			"discount"=>"0.00", 
			"gmt_create"=>"2015-05-19 09:16:43", 
			"gmt_logistics_modify"=>"2015-05-19 09:20:38", 
			"gmt_payment"=>"2015-05-19 09:20:35", 
			"gmt_send_goods"=>"2015-05-19 09:20:38", 
			"is_success"=>"T", 
			"is_total_fee_adjust"=>"N", 
			"logistics_fee"=>"0.00", 
			"logistics_payment"=>"SELLER_PAY", 
			"logistics_type"=>"DIRECT", 
			"notify_id"=>"RqPnCoPT3K9%2Fvwbh3InSN9bfmzKk3CpDC2p8BqOTbj8IE0lLjRCBiSNAHwr%2FHA48bafR", 
			"notify_time"=>"2015-05-19 09:20:39", 
			"notify_type"=>"trade_status_sync", 
			"out_trade_no"=>op.order_no, 
			"payment_type"=>"1", 
			"price"=>"0.01", 
			"quantity"=>"1", 
			"receive_address"=>"上海 上海市 普陀区 中山北路1715号 浦发广场E座 2101", 
			"receive_mobile"=>"13764886276", 
			"receive_name"=>"李一啸", 
			"receive_zip"=>"200062", 
			"seller_actions"=>"EXTEND_TIMEOUT", 
			"seller_email"=>"maotm@sina.cn", 
			"seller_id"=>"2088302722580876", 
			"subject"=>"测试交易:订单号alipay_transaction_20150519_000的寄送包裹费用", 
			"total_fee"=>"0.01", 
			"trade_no"=>"2015051900001000980052833539", 
			"trade_status"=>"WAIT_BUYER_CONFIRM_GOODS", 
			"use_coupon"=>"N", 
			"sign"=>"6e71d6515808ee1b1711b5cbee636586",
			"sign_type"=>"MD5"		
		}
	end

	let(:alipay_transaction_notify_params_1) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_transaction_20150519_000'").last

		{
			"discount"=>"0.00", 
			 "payment_type"=>"1", 
			 "subject"=>"测试交易:订单号alipay_transaction_20150519_000的寄送包裹费用", 
			 "trade_no"=>"2015051900001000980052833539", 
			 "buyer_email"=>"13764886276", 
			 "gmt_create"=>"2015-05-19 09:16:43", 
			 "notify_type"=>"trade_status_sync", 
			 "quantity"=>"1", 
			 "out_trade_no"=>op.order_no, 
			 "seller_id"=>"2088302722580876", 
			 "notify_time"=>"2015-05-19 09:16:44", 
			 "trade_status"=>"WAIT_BUYER_PAY", 
			 "is_total_fee_adjust"=>"Y", 
			 "total_fee"=>"0.01", 
			 "seller_email"=>"maotm@sina.cn", 
			 "price"=>"0.01", 
			 "buyer_id"=>"2088702362165983", 
			 "notify_id"=>"637b0413f5e684230f72804c784064c97g", 
			 "use_coupon"=>"N", 
			 "sign_type"=>"MD5", 
			 "sign"=>"d469047713581a65a7af6a54569c68dd"
		}
	end

	let(:alipay_transaction_notify_params_2) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_transaction_20150519_000'").last

		{
			"discount"=>"0.00", 
			 "logistics_type"=>"DIRECT", 
			 "receive_zip"=>"200062", 
			 "payment_type"=>"1", 
			 "subject"=>"测试交易:订单号alipay_transaction_20150519_000的寄送包裹费用", 
			 "logistics_fee"=>"0.00", 
			 "trade_no"=>"2015051900001000980052833539", 
			 "buyer_email"=>"13764886276", 
			 "gmt_create"=>"2015-05-19 09:16:43", 
			 "notify_type"=>"trade_status_sync", 
			 "quantity"=>"1", 
			 "logistics_payment"=>"SELLER_PAY", 
			 "out_trade_no"=>op.order_no, 
			 "seller_id"=>"2088302722580876", 
			 "notify_time"=>"2015-05-19 09:19:05", 
			 "trade_status"=>"WAIT_BUYER_PAY", 
			 "is_total_fee_adjust"=>"N", 
			 "total_fee"=>"0.01", 
			 "seller_email"=>"maotm@sina.cn", 
			 "price"=>"0.01", 
			 "buyer_id"=>"2088702362165983", 
			 "receive_mobile"=>"13764886276", 
			 "gmt_logistics_modify"=>"2015-05-19 09:16:43", 
			 "notify_id"=>"d0dba6d986a053eeff51f62a14621cc87g", 
			 "receive_name"=>"李一啸", 
			 "use_coupon"=>"N", 
			 "sign_type"=>"MD5", 
			 "sign"=>"d8891697d14c230a8fdb4f304188c27e", 
			 "receive_address"=>"上海 上海市 普陀区 中山北路1715号 浦发广场E座 2101"
		}
	end

	let(:alipay_transaction_notify_params_3) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_transaction_20150519_000'").last

		{
			"discount"=>"0.00", 
			 "logistics_type"=>"DIRECT", 
			 "receive_zip"=>"200062", 
			 "payment_type"=>"1", 
			 "subject"=>"测试交易:订单号alipay_transaction_20150519_000的寄送包裹费用", 
			 "logistics_fee"=>"0.00", 
			 "trade_no"=>"2015051900001000980052833539", 
			 "buyer_email"=>"13764886276", 
			 "gmt_create"=>"2015-05-19 09:16:43", 
			 "notify_type"=>"trade_status_sync", 
			 "quantity"=>"1", 
			 "logistics_payment"=>"SELLER_PAY", 
			 "out_trade_no"=>op.order_no, 
			 "seller_id"=>"2088302722580876", 
			 "notify_time"=>"2015-05-19 09:20:36", 
			 "trade_status"=>"WAIT_SELLER_SEND_GOODS", 
			 "is_total_fee_adjust"=>"N", 
			 "gmt_payment"=>"2015-05-19 09:20:35", 
			 "total_fee"=>"0.01", 
			 "seller_email"=>"maotm@sina.cn", 
			 "price"=>"0.01", 
			 "buyer_id"=>"2088702362165983", 
			 "receive_mobile"=>"13764886276", 
			 "gmt_logistics_modify"=>"2015-05-19 09:19:05", 
			 "notify_id"=>"68f8fc4ad42a4ade7f9b0fa84be1bdae7g", 
			 "receive_name"=>"李一啸", 
			 "use_coupon"=>"N", 
			 "sign_type"=>"MD5", 
			 "sign"=>"7b0f3165c05fe466c880be133cd86122", 
			 "receive_address"=>"上海 上海市 普陀区 中山北路1715号 浦发广场E座 2101"
		}
	end

	let(:alipay_transaction_notify_params_4) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_transaction_20150519_000'").last

		{
			"gmt_send_goods"=>"2015-05-19 09:20:38", 
			 "discount"=>"0.00", 
			 "logistics_type"=>"DIRECT", 
			 "receive_zip"=>"200062", 
			 "payment_type"=>"1", 
			 "subject"=>"测试交易:订单号alipay_transaction_20150519_000的寄送包裹费用", 
			 "logistics_fee"=>"0.00", 
			 "trade_no"=>"2015051900001000980052833539", 
			 "buyer_email"=>"13764886276", 
			 "gmt_create"=>"2015-05-19 09:16:43", 
			 "notify_type"=>"trade_status_sync", 
			 "quantity"=>"1", 
			 "logistics_payment"=>"SELLER_PAY", 
			 "out_trade_no"=>op.order_no, 
			 "seller_id"=>"2088302722580876", 
			 "notify_time"=>"2015-05-19 09:20:38", 
			 "trade_status"=>"WAIT_BUYER_CONFIRM_GOODS", 
			 "is_total_fee_adjust"=>"N", 
			 "gmt_payment"=>"2015-05-19 09:20:35", 
			 "total_fee"=>"0.01", 
			 "seller_email"=>"maotm@sina.cn", 
			 "price"=>"0.01", 
			 "buyer_id"=>"2088702362165983", 
			 "receive_mobile"=>"13764886276", 
			 "gmt_logistics_modify"=>"2015-05-19 09:19:05", 
			 "notify_id"=>"1ca99025f31f59eb2ffc72d23db7b1f07g", 
			 "receive_name"=>"李一啸", 
			 "use_coupon"=>"N", 
			 "sign_type"=>"MD5", 
			 "sign"=>"6a2400b262d5fa90f3d6969e7b29f9bb", 
			 "receive_address"=>"上>海 上海市 普陀区 中山北路1715号 浦发广场E座 2101"
 		}
	end

	let(:alipay_transaction_notify_params_5) do
		op=OnlinePay.where("trade_no='mypost4u_alipay_transaction_20150519_000'").last

		{
			"gmt_send_goods"=>"2015-05-19 09:20:38", 
			 "discount"=>"0.00", 
			 "logistics_type"=>"DIRECT", 
			 "receive_zip"=>"200062", 
			 "payment_type"=>"1", 
			 "subject"=>"测试交易:订单号alipay_transaction_20150519_000的寄送包裹费用", 
			 "logistics_fee"=>"0.00", 
			 "trade_no"=>"2015051900001000980052833539", 
			 "buyer_email"=>"13764886276", 
			 "gmt_create"=>"2015-05-19 09:16:43", 
			 "notify_type"=>"trade_status_sync", 
			 "quantity"=>"1", 
			 "logistics_payment"=>"SELLER_PAY", 
			 "out_trade_no"=>op.order_no, 
			 "seller_id"=>"2088302722580876", 
			 "notify_time"=>"2015-05-19 09:28:07", 
			 "trade_status"=>"TRADE_FINISHED", 
			 "is_total_fee_adjust"=>"N", 
			 "gmt_payment"=>"2015-05-19 09:20:35", 
			 "total_fee"=>"0.01", 
			 "seller_email"=>"maotm@sina.cn", 
			 "gmt_close"=>"2015-05-19 09:28:07", 
			 "price"=>"0.01", 
			 "buyer_id"=>"2088702362165983", 
			 "receive_mobile"=>"13764886276", 
			 "gmt_logistics_modify"=>"2015-05-19 09:20:38", 
			 "notify_id"=>"c146c2b1d16cc29fd7f1725eb833acee7g", 
			 "receive_name"=>"李一啸", 
			 "use_coupon"=>"N", 
			 "sign_type"=>"MD5", 
			 "sign"=>"96b46f9e79adfbece63d0e7041a10edb", 
			 "receive_address"=>"上海 上海市 普陀区 中山北路1715号 浦发广场E座 2101"
		}
	end
end