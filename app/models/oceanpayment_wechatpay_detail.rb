class OceanpaymentWechatpayDetail
	include PayDetailable
	attr_accessor :system,:country,:amount,:currency,:order_no,:description,:userid,:paytype

	def initialize(online_pay)
		if !payparams_valid("oceanpayment_wechatpay",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "oceanpayment_wechatpay payparams valid failure!!"
		end

		define_var("oceanpayment_wechatpay",online_pay)
	end

	def get_submit_info()
		trade_no=@system+"_"+@order_no


		terminal=Settings.oceanpayment_wechatpay.terminal
		secure_code=Settings.oceanpayment_wechatpay.secure_code

		post_params={
			"account"=>Settings.oceanpayment_wechatpay.account,
			"terminal"=>terminal,
			"signValue"=>"",
			"backUrl"=>Settings.oceanpayment_wechatpay.return_url,
			"noticeUrl"=>Settings.oceanpayment_wechatpay.notification_url,	#only 443 or 80
			"methods"=>"WX",
			"order_number"=>trade_no,
			"order_currency"=>@currency,
			"order_amount"=>@amount.to_s,
			"order_notes"=>@description,
			"billing_firstName"=>@userid,
			"billing_lastName"=>@userid,
			"billing_email"=>@userid.to_s+Settings.oceanpayment_wechatpay.billing_email,
			"billing_country"=>@country.upcase,
			"productName"=>"N/A"
		}

		post_params["signValue"]=get_sign_value(post_params,secure_code)


		redirect_url=Settings.oceanpayment_wechatpay.api_url
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

		def get_sign_value(post_params,secure_code)
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
				secure_code
			)
		end
end