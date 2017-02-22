class OceanpaymentUnionpayDetail
	include PayDetailable
	attr_accessor :system,:country,:amount,:currency,:order_no,:description,:userid,:paytype,:other_params

	def initialize(online_pay)
		if !payparams_valid("oceanpayment_unionpay",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "oceanpayment_unionpay payparams valid failure!!"
		end

		define_var("oceanpayment_unionpay",online_pay)
	end

	def get_submit_info()
		trade_no=@system+"_"+@order_no

		if @other_params.class.to_s=="String"
			customer_info_hash = JSON.parse @other_params.gsub("\"=>\"","\":\"")
		else
			customer_info_hash = @other_params
		end
		
		customer_id,customer_name=customer_info_hash['customer_id'],customer_info_hash['customer_name']
		customer_phone,customer_email=customer_info_hash['customer_phone'],customer_info_hash['customer_email']

		if @paytype=="unionpay_b2c"
			terminal=Settings.oceanpayment_unionpay.terminal_b2c
			secure_code=Settings.oceanpayment_unionpay.secure_code_b2c
			backUrl = Settings.oceanpayment_unionpay.return_url + "/b2c"
			noticeUrl = Settings.oceanpayment_unionpay.notification_url + "/b2c"
			company_name=customer_info_hash['company_name']
		else
			terminal=Settings.oceanpayment_unionpay.terminal_b2b
			secure_code=Settings.oceanpayment_unionpay.secure_code_b2b
			backUrl = Settings.oceanpayment_unionpay.return_url + "/b2b"
			noticeUrl = Settings.oceanpayment_unionpay.notification_url + "/b2b"
			company_name=customer_name
		end

		if @currency=="RMB"
			use_currency="CNY"
		else
			use_currency=@currency
		end

		#BUG BUG!
		Rails.logger.info("other_params: #{@other_params} , #{@other_params['customer_name']} , #{customer_name}")

		post_params={
			"account"=>Settings.oceanpayment_unionpay.account,
			"terminal"=>terminal,
			"signValue"=>"",
			"backUrl"=>backUrl,
			"noticeUrl"=>noticeUrl,	#only 443 or 80
			"methods"=>"UnionPay",
			"order_number"=>trade_no,
			"order_currency"=>use_currency,
			"order_amount"=>@amount.to_s,
			"order_notes"=>customer_id,
			"billing_firstName"=>company_name,
			"billing_lastName"=>customer_name,
			"billing_email"=>customer_email,
			"billing_phone"=>customer_phone,
			"billing_country"=>@country.upcase,
			"productSku"=>"N/A",
			"productName"=>"N/A",
			"productNum"=>"N/A",
		}

		post_params["signValue"]=get_sign_value(post_params,secure_code)


		redirect_url=Settings.oceanpayment_unionpay.api_url
		Rails.logger.info("submit_post ret params: [#{post_params}]") unless Rails.env.production?

		[redirect_url,trade_no,post_params]
	end


	private 
		def spec_payparams_valid(online_pay)
			errmsg=''

			if online_pay['other_params']['customer_phone'].blank? || 
				online_pay['other_params']['customer_name'].blank? || 
				online_pay['other_params']['customer_id'].blank? ||
				online_pay['other_params']['customer_email'].blank?
				errmsg="customer info is missing"
			end

			if online_pay['paytype']=="unionpay_b2b" && online_pay['other_params']['company_name'].blank?
				errmsg="company info is missing"
			end 


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
