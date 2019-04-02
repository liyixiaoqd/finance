class HelipayUnionpayDetail
	include PayDetailable, Encrypt

	BANKCODE_ENUM={
		"ICBC"=>"中国工商银行",
		"ABC"=>"中国农业银行",
		"CMBCHINA"=>"招商银行",
		"CCB"=>"中国建设银行",
		"BOCO"=>"交通银行",
		"BOC"=>"中国银行",
		"CMBC"=>"中国民生银行",
		"CGB"=>"广发银行",
		"HXB"=>"华夏银行",
		"POST"=>"中国邮政储蓄银行",
		"ECITIC"=>"中信银行",
		"CEB"=>"中国光大银行",
		"PINGAN"=>"平安银行",
		"CIB"=>"兴业银行",
		"SPDB"=>"浦发银行",
		"BCCB"=>"北京银行",
		"BON"=>"南京银行",
		"NBCB"=>"宁波银行",
		"BEA"=>"东亚银行",
		"SRCB"=>"上海农商银行",
		"SHB"=>"上海银行",
		"CZB"=>"浙商银行",
		"TCCB"=>"天津银行",
		"HSBANK"=>"徽商银行",
		"HFBANK"=>"恒丰银行",
		"CBHB"=>"渤海银行",
		"JSB"=>"江苏银行",
		"CITI"=>"花旗银行",
		"THX"=>"贵阳银行"
	}
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
			"serverCallbackUrl" => Settings.helipay.unionpay.b2c.notification_url,
			"pageCallbackUrl" => Settings.helipay.unionpay.b2c.return_url,
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

			if BANKCODE_ENUM[online_pay.credit_brand].blank?
				errmsg = "bankCode[#{online_pay.credit_brand}] not support"
			end

			if errmsg.blank?
				true
			else
				Rails.logger.info(errmsg)
				false
			end
		end

end