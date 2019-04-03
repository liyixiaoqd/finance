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
			elsif @paytype[0,8] == "unionpay"
				post_params["content"] = encrypt_base64(post_params, Settings.helipay.unionpay.b2c.aes_secret)			
				post_params["sign"] = sha256_sort(Settings.helipay.unionpay.b2c.sha_secret, post_params)
				post_params["merchantNo"] = Settings.helipay.unionpay.merchant_no
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


	def self.valid_reconciliation_file(filename, split, batch_id=Time.now.to_i)
		arr=[]
		File.open(filename, "r:GBK") do |f|
			f.each_line do |line|
				arr << line.chomp.split(split)
			end
		end

		valid_reconciliation(arr, batch_id, true)
	end

	def self.valid_reconciliation(content_arr, batch_id, has_title = true)
		valid_succ_num=0
		valid_fail_num=0
		valid_nosys_num=0
		valid_rescue_num=0
		errmsg = ''
		# 2019-04-02 15:57:03.004, xxxx, 399.00, 1.40, xxxx, 397.60, 5831.86, TM190402240347095642
		i = 0
		content_arr.each do |content|
			i += 1
			next if has_title == true && i ==1 

			begin
				rd = ReconciliationDetail.init( content_to_hash(content, batch_id) )
				rd.valid_and_save!

				if(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['NON_SYSTEM'])
					valid_nosys_num=valid_nosys_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'])
					valid_fail_num=valid_fail_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'])
					valid_succ_num=valid_succ_num+1
				end
			rescue => e
				valid_fail_num +=1

				Rails.logger.info("helipayt对账异常:"+e.message)

				if e.message.blank? || e.message.length>50
					tmpmsg="第#{i}行:处理出错!"
				else
					tmpmsg=e.message
				end

				if valid_rescue_num==0
					errmsg=tmpmsg
				elsif valid_rescue_num<5
					errmsg+=";"+tmpmsg
				elsif valid_rescue_num==5
					errmsg+="..."
				end
			end
		end

		outmsg="对账成功比数:#{valid_succ_num},对账失败比数:#{valid_fail_num},非系统记录比数:#{valid_nosys_num},处理异常笔数:#{valid_rescue_num}"
		
		if errmsg.length>200
			Rails.logger.info("full errmsg:#{errmsg}")
			errmsg=errmsg[0,200]+"..."
		end
		[outmsg,errmsg]
	end

	def self.content_to_hash(content, batch_id)
		paytype = {"微信扫码"=>"wechatpay", "支付宝扫码"=>"alipay"}[content[1]]

		p = {
			'timestamp'=>content[0],
			'order_no'=>content[7],
			'transaction_status'=>'SUCC',  # 默认都为成功状态
			'amt'=>content[2].to_f,
			'feeamt'=>content[3].to_f,
			'currencycode'=>"RMB",
			'payway'=>'helipay',
			'paytype'=> content[1],
			'transaction_date'=>content[0][0...10],
			'batch_id'=>batch_id,
			'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT']
		}

		Rails.logger.info(p)

		p
	end
end