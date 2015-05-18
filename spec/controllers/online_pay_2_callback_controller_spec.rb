require 'rails_helper'

describe OnlinePayCallbackController do

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
			expect(op['status']).to eq("submit_credit")

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
			
			get :sofort_abort,:status_notification=>{"transaction"=>sofort_trade_no, "time"=>"2015-05-12T07:50:14+02:00"}
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

			get :sofort_return,:status_notification=>{"transaction"=>sofort_trade_no, "time"=>"2015-05-12T07:50:14+02:00"}
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['success_url'])
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
			expect(op['status']).to eq("success_notify")
		end

		it "get alipay_oversea_return" do
			request.session[:admin]="admin"

			op=OnlinePay.where(payway: 'alipay',paytype: 'oversea',status: 'submit').last
			expect(op).not_to eq nil

			get :alipay_oversea_return,:out_trade_no=>op.trade_no
			op.reload
			expect(response.status).to eq(302)
			expect(response['Location']).to match(op['success_url'])
		end
	end

	let(:getseqId) do
		Time.now.strftime("%Y%m%d%H%M%S")
	end
end