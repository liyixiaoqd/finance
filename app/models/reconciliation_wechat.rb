class ReconciliationWechat
	include AlipayDetailable
	include PayDetailable
	attr_accessor :appid,:mch_id,:mch_key,:bill_date

	BILL_URL = "https://api.mch.weixin.qq.com/pay/downloadbill"
	WARN_FILE_PATH="check_file/finance_reconciliation/wechat"

	def initialize(bill_date,appid=nil, mch_id=nil, mch_key=nil)
		# format: 20180808
		@bill_date = bill_date.to_s[0,10].gsub(/-|\//,"")	
		@appid = appid.blank? ? Settings.wechat.appid : appid
		@mch_id = mch_id.blank? ? Settings.wechat.mch_id: mch_id
		@mch_key = mch_key.blank? ? Settings.wechat.mch_key: mch_key
		@nonce_str = SecureRandom.hex 16	# 产生的为32位长度的随机字符串
	end

	def finance_reconciliation()
		response = nil
		message = "[#{@bill_date}] </br> "
		all_num, succ_num, fail_num, rescue_num = 0, 0, 0, 0


		begin
			check_filename=WARN_FILE_PATH+"/wechat_finance_reconciliation_warn_"+@bill_date+".log"
			Rails.logger.info("check_filename:#{check_filename}")
			check_file=File.open(check_filename,"a")

			xbuilder = Builder::XmlMarkup.new(:target => xstr = "<xml>\n", :indent =>1)
			xbuilder.appid @appid
			xbuilder.mch_id  @mch_id
			xbuilder.nonce_str @nonce_str
			xbuilder.sign_type "MD5"
			xbuilder.bill_date @bill_date
			xbuilder.bill_type "ALL"

			params={
				"appid" => @appid,
				"mch_id" => @mch_id,
				"nonce_str" => @nonce_str,
				"sign_type" => "MD5",
				"bill_date" => @bill_date,
				"bill_type" => "ALL"
			}
			xbuilder.sign generate_sign_add_key(params,@mch_key).upcase

			xstr+="</xml>"
			puts("=====\n"+xstr+"\n=====")

			response = method_url_response("post",BILL_URL,true,{}, xstr)
			raise "call url failure #{response.code}" if response.code!="200"

			doc = Nokogiri::XML(response.body.force_encoding("UTF-8"))
			if doc.xpath("/xml/return_code").present? && doc.xpath("/xml/return_code").text != "SUCCESS"
				raise "failure msg: #{doc.xpath('/xml/return_msg').text}"
			end

			line_arr = response.body.split("\r\n")
			count = -1
			response.body.split("\r\n").each do |line|
				count += 1
				next if count == 0	# 第一行为表头
				break if count == line_arr.size - 2 # 倒数第二行为订单统计标题，最后一行为统计数据
				
				all_num += 1

				begin
					rd = ReconciliationDetail.init( get_single_reconciliation_hash(line) )
					rd.valid_and_save!()

					if(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'])
						fail_num += 1
					elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'])
						succ_num += 1
					end
				rescue=>e
					check_file << "[#{all_num}]:[#{line}] - #{e.message}\n"
					rescue_num += 1
				end
			end

			message += " all_num:#{all_num} = succ_num:#{succ_num} + fail_num:#{fail_num} + rescue_num:#{rescue_num}"
		rescue=>e
			message += "rescue: #{e.message}"
		ensure
			check_file.close if check_file.present?
		end

		Rails.logger.info(message)
		[message, response]
		
	end

	private
		# 交易时间,公众账号ID,商户号,子商户号,设备号,微信订单号,商户订单号,用户标识,交易类型,交易状态,付款银行,货币种类,总金额,企业红包金额,微信退款单号,商户退款单号,退款金额,企业红包退款金额,退款类型,退款状态,商品名称,商户数据包,手续费,费率
		# "`2018-08-14 17:07:37,`wx1f5593dd90b59ed3,`1494422632,`0,`,`4200000149201808145473869027,`TM180814187389110726,`o-1VYwucgSpd2kqPKfq1H71rSzoY,`JSAPI,`SUCCESS,`CFT,`CNY,`0.01,`0.00,`0,`0,`0.00,`0.00,`,`,`JSAPITEST,`,`0.00000,`0.60%"
		def get_single_reconciliation_hash(line)
			field_array = line.split(',').each do |field| field[0]='' end 	# delete `

			single_reconciliation_hash={
				'timestamp'=>field_array[0],
				'timezone'=>"GMT+8",
				'transaction_type'=>field_array[8],
				'email'=>nil,
				'name'=>field_array[7],
				'transactionid'=>field_array[5],
				'transaction_status'=>field_array[9],
				'amt'=>field_array[12].to_f,
				'currencycode'=>field_array[11] == "CNY" ? "RMB" : field_array[11],
				'feeamt'=>field_array[22].to_f,
				'netamt'=>0.0,
				'payway'=>'wechat',
				'paytype'=>'mobile_pay',
				'batch_id'=>@bill_date,
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT'],
				'order_no'=>field_array[6]
			}

			# if @paypal_reconciliation_hash['l_timezone'][i]=='GMT'
			# 	single_reconciliation_hash['timestamp']=@paypal_reconciliation_hash['l_timestamp'][i].to_time.to_s
			# else
			# 	single_reconciliation_hash['timestamp']=@paypal_reconciliation_hash['l_timestamp'][i]
			# end
			#timestamp - utc
			single_reconciliation_hash['timestamp'] = single_reconciliation_hash['timestamp'].in_time_zone(Rails.configuration.time_zone)
			single_reconciliation_hash['transaction_date']=single_reconciliation_hash['timestamp'].to_s[0,10]

			#Rails.logger.info("#{@paypal_reconciliation_hash['l_transactionid'][i]}.timezone:#{@paypal_reconciliation_hash['l_timezone'][i]},timestamp[#{@paypal_reconciliation_hash['l_timestamp'][i]}]=>[#{single_reconciliation_hash['timestamp']}]")
			single_reconciliation_hash
		end

end