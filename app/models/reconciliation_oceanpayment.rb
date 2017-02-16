class ReconciliationOceanpayment
	include PayDetailable
	attr_accessor :paytype,:startdate,:enddate

	WARN_FILE_PATH="check_file/finance_reconciliation/oceampayment"
	MAX_ORDER_NUM=100

	def initialize(paytype,startdate="",enddate="")
		@paytype=paytype

		post_day=BasicData.get_value("00A","001","oceanpayment","").to_i

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

		@reconciliation_date=current_time_format("%Y%m%d",0)
		@batch_id=1
	end


	def finance_reconciliation
		count=0
		order_nos=[]
		message="#{@startdate} - #{@enddate} </br> "
		OnlinePay.where(" (created_at >= '#{@startdate}' and created_at<= '#{@enddate}') or (updated_at >= '#{@startdate}' and updated_at<= '#{@enddate}') ")
			.where(payway: "oceanpayment",paytype: @paytype).each do |op|
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
			post_params={
				"account"=>Settings.oceanpayment_unionpay.account,
				"terminal"=>Settings.oceanpayment_unionpay.terminal_b2c,
				"signValue"=>"",
				"order_number"=>order_nos.join(",")
			}
			post_params['signValue'] = get_sign_value(post_params)
			Rails.logger.info(post_params) unless Rails.env.production?
			response=method_url_response("post",Settings.oceanpayment_unionpay.query_api_url,true,post_params)
			if response.code!="200"
				raise "main rescue:get web failure, #{Settings.oceanpayment_unionpay.query_api_url} , response.code"
			end

			result_infos=Hash.from_xml(response.body)
			p result_infos
			result_infos.each do |result|
				p result
			end
		rescue=>e
			check_file << "#{e.message}\n" 
			Rails.logger.info(e.message)
			valid_rescue_num=valid_all_num
		end

		"batch_id [ #{@batch_id} ] : </br> {all_num:#{valid_all_num} = complete_num:#{valid_complete_num} + rescue_num:#{valid_rescue_num}</br> complete_num:#{valid_complete_num} = succ_num:#{valid_succ_num} + fail_num:#{valid_fail_num} }</br>"
	end

	def get_sign_value(post_params)
		Digest::SHA256.hexdigest(
			post_params['account'].to_s +
			post_params['terminal'].to_s +
			post_params['order_number'].to_s +
			Settings.oceanpayment_unionpay.secure_code_b2c
		)
	end
end