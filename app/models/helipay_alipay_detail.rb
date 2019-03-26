class HelipayAlipayDetail
	include PayDetailable, Encrypt
	# amount 
	attr_accessor :system,:order_no,:amount,:currency,:description

	def initialize(online_pay)
		if !payparams_valid("helipay_alipay",online_pay) || !spec_payparams_valid(online_pay)
			raise "helipay_alipay payparams valid failure!!"
		end

		define_var("helipay_alipay",online_pay)
	end

	def get_submit_info()
		begin
			url,trade_no, params = get_submit_params()
			response = method_url_response("post", url, true, params, nil, "helipay")

			raise "call url failure [#{response.code}]" if response.code!="200"
			body = JSON.parse response.body
			raise "get content failure [#{response.body}]" if body["content"].blank?

			body = JSON.parse decrypt_base64(body["content"],Settings.helipay.alipay.aes_secret)
			raise "get qrCode failure: #{body['errorMessage']}" if body['errorCode']!="0000" 

			raise "no qrCode info #{body}" if body['qrCode'].blank?
			raise "no serialNumber info #{body}" if body['serialNumber'].blank?

			[body['qrCode'],body['serialNumber'],{}]
		rescue=>e
			Rails.logger.info("HelipayAlipay get_pay_pic rescue: #{e.message}")
			["","",{}]
		end

	end

	# 组装参数
	def get_submit_params()
		trade_no=@system+"_"+@order_no

		# 先初始化必填项
		post_params = {
			"productCode" => "ALIPAYSCAN",
			"orderNo" => @order_no,
			"merchantNo" => Settings.helipay.merchant_no,
			"orderAmount" => @amount.to_f,
			"goodsName" => @description,
			"period" => 1,
			"periodUnit" => "HOUR",
			"serverCallbackUrl" => Settings.helipay.alipay.notification_url	
		}


		post_params["content"] = encrypt_base64(post_params, Settings.helipay.alipay.aes_secret)
		Rails.logger.info("HELIPAY ALIPAY CONTENT = [#{post_params['content']}]")
		
		post_params["sign"] = sha256_sort(Settings.helipay.alipay.sha_secret, post_params)
		Rails.logger.info("HELIPAY ALIPAY SIGN = [#{post_params['sign']}]")



		Rails.logger.info("submit_post ret params: [#{post_params}]") unless Rails.env.production?

		[Settings.helipay.alipay.api_url,trade_no,post_params]
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