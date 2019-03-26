class HelipayUnionpayDetail
	include PayDetailable, Encrypt
	# amount 
	attr_accessor :order_no,:amount,:currency,:description,:credit_brand,:paytype

	def initialize(online_pay)
		if !payparams_valid("helipay_unionpay",online_pay) || !spec_payparams_valid(online_pay)
			raise "helipay_unionpay payparams valid failure!!"
		end

		define_var("helipay_unionpay",online_pay)
	end

	def submit()
		begin
			url, params = get_submit_params()
			response = method_url_response("post", url, true, params, nil, "helipay")

			raise "call url failure [#{response.code}]" if response.code!="200"
			body = JSON.parse response.body
			raise "get content failure [#{response.body}]" if body["content"].blank?

			body = JSON.parse decrypt_base64(body["content"],Settings.helipay.unionpay.b2c.aes_secret)
			raise "get redirectUrl failure: #{body['errorMessage']}" if body['errorCode']!="0000" 

			raise "no redirectUrl info #{body}" if body['redirectUrl'].blank?
			raise "no serialNumber info #{body}" if body['serialNumber'].blank?

			html_content = Base64.encode64(body['redirectUrl'])

			["success", html_content, body['serialNumber'], "false", "", 2]
		rescue=>e
			Rails.logger.info("HelipayAlipay get_pay_pic rescue: #{e.message}")
			["failure", "", "", "false", e.message, 2]
		end

	end

	# 组装参数
	def get_submit_params()
		# 先初始化必填项
		post_params = {
			"productCode" => "ONLINEB2C",
			"orderNo" => @order_no,
			"merchantNo" => Settings.helipay.unionpay.merchant_no,
			"orderAmount" => @amount.to_f,
			"bankCode" => @credit_brand,
			"business" => "B2C",
			"goodsName" => @description,
			"period" => 1,
			"periodUnit" => "HOUR",
			"serverCallbackUrl" => Settings.helipay.unionpay.notification_url,
			"pageCallbackUrl" => Settings.helipay.unionpay.return_url,
		}


		post_params["content"] = encrypt_base64(post_params, Settings.helipay.unionpay.b2c.aes_secret)
		Rails.logger.info("HELIPAY UNIONPAY CONTENT = [#{post_params['content']}]")
		
		post_params["sign"] = sha256_sort(Settings.helipay.unionpay.b2c.sha_secret, post_params)
		Rails.logger.info("HELIPAY UNIONPAY SIGN = [#{post_params['sign']}]")



		Rails.logger.info("submit_post ret params: [#{post_params}]") unless Rails.env.production?

		[Settings.helipay.unionpay.api_url, post_params]
	end


	private 
		def spec_payparams_valid(online_pay)
			errmsg=''

			if online_pay.currency.blank? || !["CNY","RMB"].include?(online_pay.currency)
				errmsg = "currency must be CNY for [#{online_pay.currency}]"
			end

			if errmsg.blank?
				true
			else
				Rails.logger.info(errmsg)
				false
			end
		end

end