require 'rails_helper'

describe OnlinePayController do
	# describe "online_pay submit_credit cal:" do
	# 	it "post submit_creditcard" do
	# 		request.session[:admin]="admin"

	# 		@op=OnlinePay.where(payway: 'paypal',status: 'submit_credit').last
	# 		expect(@op).not_to eq nil
	# 		post :submit_creditcard,credit_params()

	# 		expect(response.status).to eq(400)
	# 		@op.reload
	# 		expect(@op['reason']).to eq("Payment has not been authorized by the user.")
	# 	end
	# end


	# let(:credit_params) do

	# 	{
	# 		'payway'=>'paypal',
	# 		'paytype'=>'',
	# 		'trade_no'=>@op['trade_no'],
	# 		'amount'=>@op['amount'],
	# 		'currency'=>'EUR',
	# 		'ip'=>@op['ip'],
	# 		'brand' => 'visia', 
	# 		'number' => '1111111111',
	# 		'verification_value' => '315',
	# 		'month' => '12',
	# 		'year' => '15',
	# 		'first_name' => 'ly',
	# 		'last_name' => 'xxx',
	# 		'userid' => @op['userid']
	# 	}
	# end
end