class ReconciliationHelipay
	include PayDetailable, Encrypt
	attr_accessor :order_no, :paytype

	PRODUCT_CODE_ENUM = {
		"alipay" => "ALIPAYSCAN",
		"wechatpay" => "WXPAYSCAN",
	}

	def initialize(order_no, paytype)
		@order_no = order_no
		@paytype = paytype
	end

	def verify_single_order()
		flag,reconciliation_id = false, nil

		begin
			post_params = {
				"productCode" => PRODUCT_CODE_ENUM[@paytype],
				"orderNo" => @order_no,
				"merchantNo" => Settings.helipay.merchant_no
			}

			if @paytype == "alipay"
				post_params["content"] = encrypt_base64(post_params, Settings.helipay.alipay.aes_secret)			
				post_params["sign"] = sha256_sort(Settings.helipay.alipay.sha_secret, post_params)
			elsif @paytype == "wechatpay"
				post_params["content"] = encrypt_base64(post_params, Settings.helipay.wechatpay.aes_secret)			
				post_params["sign"] = sha256_sort(Settings.helipay.wechatpay.sha_secret, post_params)
			else
				nil
			end

			response = method_url_response("post", Settings.helipay.public.query_url, true, post_params, nil, "helipay")
			raise "call url failure [#{response.code}]" if response.code!="200"

			body = JSON.parse response.body
			raise "get content failure [#{response.body}]" if body["content"].blank?

			if @paytype == "alipay"
				body = JSON.parse decrypt_base64(body["content"],Settings.helipay.alipay.aes_secret)
			elsif @paytype == "wechatpay"
				body = JSON.parse decrypt_base64(body["content"],Settings.helipay.wechatpay.aes_secret)
			else
				nil
			end
				
			raise "get qrCode failure: #{body['errorMessage']}" if body['errorCode']!="0000" 

			if body['orderStatus'] == "SUCCESS"
				flag = true
				reconciliation_id = body['serialNumber']
			end
		rescue=>e
			Rails.logger.info("HELIPAY verify_single_order rescue: #{e.message}")
			flag = false
		end

		[flag,reconciliation_id]
	end
end