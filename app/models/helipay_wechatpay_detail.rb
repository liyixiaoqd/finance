class HelipayWechatpayDetail
	include PayDetailable, Encrypt
	# amount 
	attr_accessor :order_no,:amount,:currency,:description

	# 参数与支付宝一致, 公用
	def initialize(online_pay)
		if !payparams_valid("helipay_alipay",online_pay) || !spec_payparams_valid(online_pay)
			raise "helipay_wechatpay payparams valid failure!!"
		end

		define_var("helipay_alipay",online_pay)
	end

	def submit()
		begin
			url, params = get_submit_params()
			response = method_url_response("post", url, true, params, nil, "helipay")

			raise "call url failure [#{response.code}]" if response.code!="200"
			body = JSON.parse response.body
			raise "get content failure [#{response.body}]" if body["content"].blank?

			body = JSON.parse decrypt_base64(body["content"],Settings.helipay.wechatpay.aes_secret)
			raise "get qrCode failure: #{body['errorMessage']}" if body['errorCode']!="0000" 

			raise "no qrCode info #{body}" if body['qrCode'].blank?
			raise "no serialNumber info #{body}" if body['serialNumber'].blank?

			["success", body['qrCode'], body['serialNumber'], "false", "", 1]
		rescue=>e
			Rails.logger.info("HelipayWechatpay get_pay_pic rescue: #{e.message}")
			["failure", "", "", "false", e.message, 1]
		end

	end

	# 组装参数
	def get_submit_params()
		# 先初始化必填项
		post_params = {
			"productCode" => "WXPAYSCAN",
			"orderNo" => @order_no,
			"merchantNo" => Settings.helipay.merchant_no,
			"orderAmount" => @amount.to_f,
			"goodsName" => @description,
			"period" => 1,
			"periodUnit" => "HOUR",
			"serverCallbackUrl" => Settings.helipay.wechatpay.notification_url	
		}


		post_params["content"] = encrypt_base64(post_params, Settings.helipay.wechatpay.aes_secret)
		Rails.logger.info("HELIPAY WECHATPAY CONTENT = [#{post_params['content']}]")
		
		post_params["sign"] = sha256_sort(Settings.helipay.wechatpay.sha_secret, post_params)
		Rails.logger.info("HELIPAY WECHATPAY SIGN = [#{post_params['sign']}]")



		Rails.logger.info("submit_post ret params: [#{post_params}]") unless Rails.env.production?

		[Settings.helipay.wechatpay.api_url, post_params]
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