class OceanpaymentUnionpayDetail
	include PayDetailable
	attr_accessor :system,:country,:amount,:currency,:order_no,:description,:userid

	def initialize(online_pay)
		if !payparams_valid("oceanpayment_unionpay",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "oceanpayment_unionpay payparams valid failure!!"
		end

		define_var("oceanpayment_unionpay",online_pay)
	end

	def get_submit_info()
		trade_no=@system+"_"+@order_no

		post_params={
			"account"=>Settings.oceanpayment_unionpay.account,
			"terminal"=>Settings.oceanpayment_unionpay.terminal_b2c,
			"signValue"=>"",
			"backUrl"=>Settings.oceanpayment_unionpay.return_url,
			"noticeUrl"=>Settings.oceanpayment_unionpay.notification_url,	#only 443 or 80
			"methods"=>"UnionPay",
			"order_number"=>trade_no,
			"order_currency"=>@currency,
			"order_amount"=>@amount.to_s,
			"order_notes"=>@description,
			"billing_firstName"=>"N/A",
			"billing_lastName"=>"N/A",
			"billing_email"=>userid.to_s+Settings.oceanpayment_unionpay.billing_email,
			"billing_country"=>@country,
			"productSku"=>"N/A",
			"productName"=>"N/A",
			"productNum"=>"N/A",
		}

		post_params["signValue"]=get_sign_value(post_params)


		redirect_url=Settings.oceanpayment_unionpay.api_url
		Rails.logger.info(post_params) unless Rails.env.production?

		[redirect_url,trade_no,post_params]
	end


	private 
		def spec_payparams_valid(online_pay)
			errmsg=''

			if errmsg.blank?
				true
			else
				Rails.logger.info(errmsg)
				false
			end
		end

		def get_sign_value(post_params)
			Digest::SHA256.hexdigest(
				post_params['account'].to_s +
				post_params['terminal'].to_s +
				post_params['backUrl'].to_s +
				post_params['order_number'].to_s +
				post_params['order_currency'].to_s +
				post_params['order_amount'].to_s +
				post_params['billing_firstName'].to_s +
				post_params['billing_lastName'].to_s +
				post_params['billing_email'].to_s +
				Settings.oceanpayment_unionpay.secure_code_b2c
			)
		end
end