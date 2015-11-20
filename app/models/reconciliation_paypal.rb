class ReconciliationPaypal
	include AlipayDetailable
	include PayDetailable
	attr_accessor :service,:startdate,:enddate

	WARN_FILE_PATH="check_file/finance_reconciliation/paypal"
	MAX_CALL_TIMES=10
	# https://developer.paypal.com/webapps/developer/docs/classic/api/merchant/TransactionSearch_API_Operation_NVP/
	# STARTDATE		(Required) The earliest transaction date at which to start the search.
	# ENDDATE		(Optional) The latest transaction date to be included in the search.
	# ......
	def initialize(service,startdate="",enddate="",country)
		@service=service
		post_day=BasicData.get_value("00A","001","paypal","").to_i
		if(startdate.blank?)
			@startdate=Time.now.at_beginning_of_day-post_day.day
		else
			@startdate=startdate.to_time
		end

		if(enddate.blank?)
			@enddate=Time.now.at_beginning_of_day-post_day.day+1.day
		else
			@enddate=enddate.to_time
		end		

		@paypal_reconciliation_hash=init_paypal_reconciliation_hash()
		@reconciliation_date=current_time_format("%Y%m%d",0)
		@batch_id=1	# 001
		@country=country
		Rails.logger.info("TRANSACTION SEARCH : #{@startdate} -- #{@enddate}")
	end

	def get_reconciliation(startdate,enddate,options_hash={})
		options={
			'METHOD' => self.service,
			'VERSION' => Settings.paypal.paypal_api_other_version,
			'STARTDATE' => startdate,
			# 'CURRENCYCODE' => 'EUR',
			# 'AMT' => 105,
			'ENDDATE' => enddate
		}.merge(options_hash)
		Rails.logger.info("get_reconciliation:#{options}")

		if @country=="de"
			options['USER']=Settings.paypal.login_de
			options['PWD']=Settings.paypal.password_de
			options['SIGNATURE']=Settings.paypal.signature_de
		elsif @country=="at"
			options['USER']=Settings.paypal.login_at
			options['PWD']=Settings.paypal.password_at
			options['SIGNATURE']=Settings.paypal.signature_at
		elsif @country=="gb"
			options['USER']=Settings.paypal.login_gb
			options['PWD']=Settings.paypal.password_gb
			options['SIGNATURE']=Settings.paypal.signature_gb
		elsif @country=="nl"
			options['USER']=Settings.paypal.login_nl
			options['PWD']=Settings.paypal.password_nl
			options['SIGNATURE']=Settings.paypal.signature_nl
		else
			Rails.logger.warn("NO COUNTRY SET:#{country}")
		end
			

		reconciliation_url=Settings.paypal.paypal_api_other_uri
		Rails.logger.info(reconciliation_url)
		method_url_response("post",reconciliation_url,true,options)
		#Rails.logger.info(response.body)
		#{}"#{self.service}</br>#{reconciliation_url}</br></br>#{CGI.unescape(response.body)}"
	end

	def finance_reconciliation()
		hour_step=BasicData.get_value("00A","002","paypal","").to_i
		message="#{@startdate} - #{@enddate} </br> "
		for h in (0...24/hour_step)
			Rails.logger.info("#{@startdate},#{h},#{hour_step}")
			tmp_start = (@startdate+ (h*hour_step).hour).strftime("%Y-%m-%dT%H:%M:%SZ")
			tmp_end =  (@startdate+ ((h+1)*hour_step).hour).strftime("%Y-%m-%dT%H:%M:%SZ")

			Rails.logger.info("#{h}: #{tmp_start} - #{tmp_end}")
			message=message+valid_reconciliation(get_reconciliation(tmp_start,tmp_end,{}))

			@batch_id=@batch_id+1
			@paypal_reconciliation_hash=init_paypal_reconciliation_hash()

			if @batch_id > MAX_CALL_TIMES
				Rails.logger.warn("MAX_CALL_TIME:#{MAX_CALL_TIMES} AND BREAK!!!!!!")
			end
		end

		message
	end

	def valid_reconciliation(response)
		response_to_hash_paypal!(response)
		if @paypal_reconciliation_hash.blank?
			return "response Analytical failure"
		end

		
		check_filename=WARN_FILE_PATH+"/paypal_finance_reconciliation_warn_"+@reconciliation_date+".log"
		Rails.logger.info("check_filename:#{check_filename}")
		check_file=File.open(check_filename,"a")

		valid_all_num=@paypal_reconciliation_hash['l_transactionid'].size
		valid_complete_num=0
		valid_succ_num=0
		valid_fail_num=0
		valid_rescue_num=0

		for i in (0...@paypal_reconciliation_hash['l_transactionid'].size)
			begin
				rd=ReconciliationDetail.init( get_single_reconciliation_hash(i) )
				rd.valid_and_save!()
				# rd.set_params_by_transactionid!()

				# if rd.online_pay_id.blank?
				# 	rd.set_flag!(ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'],"get online_pay_failure:#{rd.transactionid}")
				# else
				# 	rd.set_flag_by_status_and_amount!()
				# end
				
				# rd.save!()

				valid_complete_num=valid_complete_num+1
				if(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'])
					valid_fail_num=valid_fail_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'])
					valid_succ_num=valid_succ_num+1
				end
			rescue => e
				check_file << "#{rd.warn_to_file(e.message)}\n" unless rd.blank?
				Rails.logger.info(e.message)
				valid_rescue_num=valid_rescue_num+1
			end
		end
		check_file.close

		"batch_id [ #{@batch_id} ] : </br> {all_num:#{valid_all_num} = complete_num:#{valid_complete_num} + rescue_num:#{valid_rescue_num}</br> complete_num:#{valid_complete_num} = succ_num:#{valid_succ_num} + fail_num:#{valid_fail_num} }</br>"
	end

	def has_pay_order(email,amt,starttime,endtime)
		flag=false
		message='no record found'
		reconciliation_id=''
		callback_status=''

		if @country == "de"
			currencycode="EUR"
		elsif @country == "nl"
			currencycode="EUR"
		elsif @country == "gb"
			currencycode="GBP"
		elsif @country == "at"
			currencycode="EUR"
		else
			currencycode="EUR"
		end

		begin
			params={
				"EMAIL"=>email,
				"CURRENCYCODE"=>currencycode,
				"AMT"=>amt.to_s
			}
			response=''
			Timeout::timeout(22){
				# response=get_reconciliation((Time.now-60).gmtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
				# 	(Time.now+60).gmtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
				# 	params)
				response=get_reconciliation(starttime,endtime,params)
			}
			Rails.logger.info(response.body)
			response_to_hash_paypal!(response)
			if @paypal_reconciliation_hash.blank?
				raise "no pay record get"
			end

			for i in (0...@paypal_reconciliation_hash['l_transactionid'].size)
				srh=get_single_reconciliation_hash(i)
				rd=ReconciliationDetail.find_by_transactionid(srh['transactionid'])
				if rd.blank?
					flag=true
					message=''
					reconciliation_id=srh['transactionid']
					callback_status==srh['l_status']

					break
				else
					Rails.logger.info("repeat onlinepay [ #{i} ]:#{rd.order_no},#{rd.transaction_id}")
				end
			end
		rescue=>e
			Rails.logger.info("has_pay_order failure!! :#{e.message}")
			message=e.message
			flag=false
		end

		Rails.logger.info("has_pay_order:#{flag}:#{reconciliation_id},#{callback_status},#{message}")
		[flag,message,reconciliation_id,callback_status]
	end

	private	 
		def response_to_hash_paypal!(response)
			return nil unless response.code=="200"

			array_body=response.body.split('&')
			#return nil if !array_body.include?("ACK=Success") || array_body.size==1

			return nil unless array_body.include?("ACK=Success") || array_body.include?("ACK=SuccessWithWarning")

			# paypal_reconciliation_hash=init_paypal_reconciliation_hash()

			array_body.each do |array_each|
				array_field=array_each.split("=")
				if array_field.size!=2 
					Rails.logger.warn("Analytical failure - array split : #{array_each}")
					next
				end

				field_match = array_field[0].match(/\d+/)
				#Rails.logger.info("Analytical : #{array_field[0]}")
				if field_match.blank? || field_match.pre_match.blank?
					Rails.logger.warn("Analytical failure - field_match : #{array_field[0]}")
					next
				end

				field_name=CGI.unescape(field_match.pre_match).downcase
				field_position=field_match.to_s.to_i
				field_value=CGI.unescape(array_field[1])

				if @paypal_reconciliation_hash.include?(field_name) 
					@paypal_reconciliation_hash[field_name][field_position]=field_value
					#Rails.logger.info("PAYPAL ReconciliationDetail Analytical#{field_name}:#{field_value}")
				else
					Rails.logger.warn("Analytical failure - paypal_reconciliation_hash : #{array_each} - #{field_name}")
					next
				end
				# case field_name
				# when 'l_timestamp' then @paypal_reconciliation_hash['l_timestamp'][field_position]=field_value
				# when 'l_timezone' then @paypal_reconciliation_hash['l_timezone'][field_position]=field_value
				# when 'l_type' then @paypal_reconciliation_hash['l_type'][field_position]=field_value
				# when 'l_email' then @paypal_reconciliation_hash['l_email'][field_position]=field_value
				# when 'l_name' then @paypal_reconciliation_hash['l_name'][field_position]=field_value
				# when 'l_transactionid' then @paypal_reconciliation_hash['l_transactionid'][field_position]=field_value
				# when 'l_status' then @paypal_reconciliation_hash['l_status'][field_position]=field_value
				# when 'l_amt' then @paypal_reconciliation_hash['l_amt'][field_position]=field_value
				# when 'l_currencycode' then @paypal_reconciliation_hash['l_currencycode'][field_position]=field_value
				# when 'l_feeamt' then @paypal_reconciliation_hash['l_feeamt'][field_position]=field_value
				# when 'l_netamt' then @paypal_reconciliation_hash['l_netamt'][field_position]=field_value
				# else
				# 	Rails.logger.warn("Analytical failure #{array_each} - #{field_name}")
				# 	next
				# end	
			end

			#Rails.logger.info("==========================\n#{@paypal_reconciliation_hash}")
		end

		def get_single_reconciliation_hash(i)
			single_reconciliation_hash={
				'timestamp'=>@paypal_reconciliation_hash['l_timestamp'][i],
				'timezone'=>@paypal_reconciliation_hash['l_timezone'][i],
				'transaction_type'=>@paypal_reconciliation_hash['l_type'][i],
				'email'=>@paypal_reconciliation_hash['l_email'][i],
				'name'=>@paypal_reconciliation_hash['l_name'][i],
				'transactionid'=>@paypal_reconciliation_hash['l_transactionid'][i],
				'transaction_status'=>@paypal_reconciliation_hash['l_status'][i],
				'amt'=>@paypal_reconciliation_hash['l_amt'][i].to_f,
				'currencycode'=>@paypal_reconciliation_hash['l_currencycode'][i],
				'feeamt'=>@paypal_reconciliation_hash['l_feeamt'][i].to_f,
				'netamt'=>@paypal_reconciliation_hash['l_netamt'][i].to_f,
				'payway'=>'paypal',
				'paytype'=>'',
				'batch_id'=>@reconciliation_date+"_"+sprintf("%03d",@batch_id),
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT']
			}

			# if @paypal_reconciliation_hash['l_timezone'][i]=='GMT'
			# 	single_reconciliation_hash['timestamp']=@paypal_reconciliation_hash['l_timestamp'][i].to_time.to_s
			# else
			# 	single_reconciliation_hash['timestamp']=@paypal_reconciliation_hash['l_timestamp'][i]
			# end
			single_reconciliation_hash['transaction_date']=single_reconciliation_hash['timestamp'].to_time.to_s[0,10]

			#Rails.logger.info("#{@paypal_reconciliation_hash['l_transactionid'][i]}.timezone:#{@paypal_reconciliation_hash['l_timezone'][i]},timestamp[#{@paypal_reconciliation_hash['l_timestamp'][i]}]=>[#{single_reconciliation_hash['timestamp']}]")
			single_reconciliation_hash
		end

		def init_paypal_reconciliation_hash
			{
				'l_timestamp'=>[],
				'l_timezone'=>[],
				'l_type'=>[],
				'l_email'=>[],
				'l_name'=>[],
				'l_transactionid'=>[],
				'l_status'=>[],
				'l_amt'=>[],
				'l_currencycode'=>[],
				'l_feeamt'=>[],
				'l_netamt'=>[]
			}	
		end
end