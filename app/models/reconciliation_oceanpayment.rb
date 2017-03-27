class ReconciliationOceanpayment
	include PayDetailable
	attr_accessor :paytype,:startdate,:enddate,:system

	WARN_FILE_PATH="check_file/finance_reconciliation/oceampayment"
	MAX_ORDER_NUM=40

	def initialize(paytype,system,startdate="",enddate="")
		@paytype=paytype

		post_day=BasicData.get_value("00A","001","oceanpayment","").to_i

		if(startdate.blank?)
			@startdate=Time.zone.now.at_beginning_of_day-post_day.day
		else
			@startdate=startdate.to_time
		end

		if(enddate.blank?)
			@enddate=Time.zone.now.at_beginning_of_day
		else
			@enddate=enddate.to_time
		end	

		@system=system
		@reconciliation_date=current_time_format("%Y%m%d",0)
		@batch_id=1
	end


	def finance_reconciliation
		count=0
		order_nos=[]
		message="#{@startdate} - #{@enddate}  , SYSTEM[#{@system}] </br> "
		OnlinePay.where(" (created_at >= '#{@startdate}' and created_at<= '#{@enddate}') or (updated_at >= '#{@startdate}' and updated_at<= '#{@enddate}') ")
			.where(payway: "oceanpayment",paytype: @paytype,system: @system).each do |op|
				count+=1
				order_nos<< op.trade_no
				if count==MAX_ORDER_NUM
					message=message+valid_reconciliation(order_nos)
					order_nos=[]
					count=0
					@batch_id+=1
				end
		end

		if count>0
			message=message+valid_reconciliation(order_nos)
			@batch_id+=1
		end

		message
	end

	def valid_reconciliation(order_nos)
		check_filename=WARN_FILE_PATH+"/oceampayment_finance_reconciliation_warn_"+@reconciliation_date+".log"
		Rails.logger.info("check_filename:#{check_filename}")
		check_file=File.open(check_filename,"a")

		valid_all_num=order_nos.size
		valid_complete_num=0
		valid_succ_num=0
		valid_fail_num=0
		valid_rescue_num=0


		begin
			if @system=="quaie"
				if @paytype=="unionpay_b2c"
					account=Settings.oceanpayment_unionpay.quaie.account
					terminal=Settings.oceanpayment_unionpay.quaie.terminal
					secure_code=Settings.oceanpayment_unionpay.quaie.secure_code
					query_api_url = Settings.oceanpayment_unionpay.quaie.query_api_url
				else
					account=Settings.oceanpayment_wechatpay.quaie.account
					terminal=Settings.oceanpayment_wechatpay.quaie.terminal
					secure_code=Settings.oceanpayment_wechatpay.quaie.secure_code
					query_api_url = Settings.oceanpayment_wechatpay.quaie.query_api_url
				end
			else
				if @paytype=="unionpay_b2c"
					account = Settings.oceanpayment_unionpay.account_b2c
					terminal = Settings.oceanpayment_unionpay.terminal_b2c
					secure_code = Settings.oceanpayment_unionpay.secure_code_b2c
					query_api_url = Settings.oceanpayment_unionpay.query_api_url_b2c
				elsif @paytype=="unionpay_b2b"
					account = Settings.oceanpayment_unionpay.account_b2b
					terminal = Settings.oceanpayment_unionpay.terminal_b2b
					secure_code = Settings.oceanpayment_unionpay.secure_code_b2b
					query_api_url = Settings.oceanpayment_unionpay.query_api_url_b2b
				else
					account = Settings.oceanpayment_wechatpay.account
					terminal =  Settings.oceanpayment_wechatpay.terminal
					secure_code = Settings.oceanpayment_wechatpay.secure_code
					query_api_url = Settings.oceanpayment_wechatpay.query_api_url
				end
			end
				
			post_params={
				"account"=>account,
				"terminal"=>terminal,
				"signValue"=>"",
				"order_number"=>order_nos.join(",")
			}
			post_params['signValue'] = get_sign_value(post_params,secure_code)
			Rails.logger.info(post_params) unless Rails.env.production?
			response=method_url_response("post",query_api_url,true,post_params)
			if response.code!="200"
				raise "main rescue:get web failure, #{query_api_url} , response.code"
			end

			result_infos=Hash.from_xml(response.body)
			#单条记录
			if result_infos['response']['paymentInfo'].class.to_s=="Hash"
				payinfo = result_infos['response']['paymentInfo']
				valid_flag,valid_msg=valid_reconciliation_process(payinfo)
				if valid_msg.present?
					check_file << "#{valid_msg}\n"
					valid_rescue_num+=1
				else
					valid_complete_num+=1
					if valid_flag==true
						valid_succ_num+=1
					else
						valid_fail_num+=1
					end
				end
			else
				result_infos['response']['paymentInfo'].each do |payinfo|
					valid_flag,valid_msg=valid_reconciliation_process(payinfo)
					if valid_msg.present?
						check_file << "[#{payinfo['order_number']}] - [#{valid_msg}]\n"
						valid_rescue_num+=1
					else
						valid_complete_num+=1
						check_file<< "[#{payinfo['order_number']}] - [#{valid_flag}]\n"
						if valid_flag==true
							valid_succ_num+=1
						else
							valid_fail_num+=1
						end
					end
				end
			end
		rescue=>e
			check_file << "#{e.message}\n" 
			Rails.logger.info(e.message)
			valid_rescue_num=valid_all_num
		end
		check_file.close

		"batch_id [ #{@batch_id} ] : </br> {all_num:#{valid_all_num} = complete_num:#{valid_complete_num} + rescue_num:#{valid_rescue_num}</br> complete_num:#{valid_complete_num} = succ_num:#{valid_succ_num} + fail_num:#{valid_fail_num} }</br>"
	end

	def valid_reconciliation_process(payinfo)
		valid_flag,msg=true,nil
		begin
			op=OnlinePay.find_by(payway: "oceanpayment",paytype: @paytype,trade_no: payinfo['order_number'])
			if op.blank?
				raise "no trade_no [#{payinfo['order_number']}] record!"
			end
			rd=op.reconciliation_detail

			if rd.present? && rd.confirm_flag==ReconciliationDetail::CONFIRM_FLAG['SUCC']
				#has valid!
				gen_callback_task(payinfo,rd)
				return [true,nil]
			end

			Rails.logger.info("is pay? [#{op.order_no}] [#{op.status}]  <-> [#{payinfo['payment_results']}]")
			if payinfo['payment_results'].to_s=="1"	#实际支付成功
				if rd.present?	#对账存在记录 
					if rd.online_pay_status=~ /^success/ && payinfo['order_amount'].to_f==rd.amt   	#财务系统支付成功
						rd.set_flag!(ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'],"")
					else	#财务系统未支付成功
						valid_flag=false
						if payinfo['order_amount'].to_f!=rd.amt
							rd.set_flag!(ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'],"amount not match: #{payinfo['order_amount']} <=> #{rd.amt}")
						else
							rd.set_flag!(ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'],"#{rd.payway} is success_pay but online_pay is #{rd.online_pay_status}")
						end
					end
				else	#对账不存在记录 
					valid_flag=false
					if op.reconciliation_id.blank?
						op.reconciliation_id=op.trade_no
						op.save!()
					end
					rd=op.set_reconciliation
					rd.timestamp = payinfo['payment_dateTime'].in_time_zone("Beijing").in_time_zone(Rails.configuration.time_zone)
					rd.transaction_date = rd.timestamp.to_s[0,10]

					rd.set_flag!(ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'],"#{rd.payway} is success_pay but online_pay is #{rd.online_pay_status}")
				end
			else	#实际未支付成功
				if rd.present? && rd.online_pay_status=~ /^success/ 	#财务系统支付成功
					valid_flag=false
					rd.set_flag!(ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'],"#{rd.payway} is failure[#{payinfo['payment_results']},#{payinfo['payment_details']}] but online_pay is #{rd.online_pay_status}")
				end
			end

			if rd.present?
				gen_callback_task(payinfo,rd) if rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC']
				rd.save!() 
			end
		rescue=>e
			msg=e.message
		end

		[valid_flag,msg]
	end

	#
	def gen_callback_task(payinfo,reconciliation_detail)
		CallQueue.oceanpayment_push_task_save!(reconciliation_detail.id,payinfo['payment_id'],reconciliation_detail.system)
	end

	def get_sign_value(post_params,secure_code)
		Digest::SHA256.hexdigest(
			post_params['account'].to_s +
			post_params['terminal'].to_s +
			post_params['order_number'].to_s +
			secure_code
		)
	end

	def self.push_track_info(online_pay)
		push_flag=false
		begin
			raise "push_track_info failure: no online_pay input" if online_pay.blank?
			raise "[#{online_pay.order_no}] no track_info get" if online_pay.online_pay_track_info.blank?

			if online_pay.paytype=="unionpay_b2c"
				account = Settings.oceanpayment_unionpay.account_b2c
				terminal = Settings.oceanpayment_unionpay.terminal_b2c
				secure_code = Settings.oceanpayment_unionpay.secure_code_b2c	
			elsif online_pay.paytype=="unionpay_b2b"
				account = Settings.oceanpayment_unionpay.account_b2b
				terminal = Settings.oceanpayment_unionpay.terminal_b2b
				secure_code = Settings.oceanpayment_unionpay.secure_code_b2b
			else
				account = Settings.oceanpayment_wechatpay.account
				terminal =  Settings.oceanpayment_wechatpay.terminal
				secure_code = Settings.oceanpayment_wechatpay.secure_code
			end

			post_params={
				"account"=>account,
				"terminal"=>terminal,
				"signValue"=>"",
				"payment_id"=>online_pay.reconciliation_detail.transactionid,
				"tracking_number"=>online_pay.online_pay_track_info.ishpmt_nums[0,200],
				"tracking_site"=>online_pay.online_pay_track_info.tracking_urls[0,100],
				"tracking_handler"=>Settings.oceanpayment_unionpay.track_handler
			}

			post_params['signValue'] = get_track_sign_value(post_params,secure_code)
			Rails.logger.info(post_params) unless Rails.env.production?
			response=method_url_response_by_class("post",Settings.oceanpayment_unionpay.track_url,true,post_params)
			if response.code!="200"
				raise "main rescue:get web failure, #{Settings.oceanpayment_unionpay.track_url} , response.code"
			end

			result_infos=Hash.from_xml(response.body)
			if result_infos['response']['tracking_results'].to_i==1
				push_flag=true
			else
				raise "ReconciliationOceanpayment.push_track_info failure: [#{result_infos['response']['tracking_results']}]"
			end
		rescue=>e
			p "#{e.message}"
			push_flag=false
		end

		push_flag
	end

	def self.get_track_sign_value(post_params,secure_code)
		Digest::SHA256.hexdigest(
			post_params['account'].to_s +
			post_params['terminal'].to_s +
			post_params['payment_id'].to_s +
			post_params['tracking_number'].to_s +
			post_params['tracking_site'].to_s +
			post_params['tracking_handler'].to_s +
			secure_code
		)
	end
end