require 'nokogiri' 

class ReconciliationAlipayTransaction
	include AlipayDetailable
	include PayDetailable
	attr_accessor :service,:seller_email,:page_no,:gmt_start_time,:gmt_end_time,:page_size

	WARN_FILE_PATH="check_file/finance_reconciliation/alipay_transaction"
	MAX_CALL_TIMES=10
	# page_no			查询页号
	# gmt_start_time		账务查询开始时间
	# gmt_end_time		账务查询结束时间
	# logon_id			交易收款账户
	# iw_account_log_id		账务流水号
	# trade_no			支付宝交易号
	# merchant_out_order_no	商户订单号
	# deposit_bank_no		充值网银流水号
	# page_size			分页大小
	# trans_code			交易类型代码

	def initialize(service,seller_email,page_no=1,gmt_start_time="",gmt_end_time="",page_size=1000)
		@service=service
		@seller_email=seller_email
		@page_no=page_no.to_i
		@page_size=page_size

		post_day=BasicData.get_value("00A","001","alipay","transaction").to_i
		if(gmt_start_time.blank?)
			@gmt_start_time=current_time_format("%Y-%m-%d 00:00:00",0-post_day)
		else
			@gmt_start_time=gmt_start_time
		end

		if(gmt_end_time.blank?)
			@gmt_end_time=current_time_format("%Y-%m-%d 00:00:00",1-post_day)
		else
			@gmt_end_time=gmt_end_time
		end

		@reconciliation_date=current_time_format("%Y%m%d",0)
		@alipay_transaction_detail=""
		@batch_id=1
	end

	def get_reconciliation()
		if(self.service=="export_trade_account_report")
			get_reconciliation_count()
		elsif(self.service=="account.page.query")
			get_reconciliation_detail()
		else
			"no inteface to #{self.service} can be get!!"
		end
	end

	def finance_reconciliation()
		has_next=true 	#first call interface
		message="#{@gmt_start_time} - #{@gmt_end_time} </br> "
		while  has_next 
			has_next=get_reconciliation_detail()

			message=message+valid_reconciliation()

			#Rails.logger.info("#{has_next.to_s},#{self.page_no}")
			@page_no=@page_no+1
			@batch_id=@batch_id+1
			@alipay_transaction_detail=""

			if @batch_id > MAX_CALL_TIMES
				Rails.logger.warn("MAX_CALL_TIME:#{MAX_CALL_TIMES} AND BREAK!!!!!!")
			end
		end

		message
	end

	def valid_reconciliation
		if @alipay_transaction_detail.blank?
			return "response Analytical failure" 
		end

		check_filename=WARN_FILE_PATH+"/alipay_transaction_finance_reconciliation_warn_"+@reconciliation_date+".log"
		Rails.logger.info("check_filename:#{check_filename}")
		check_file=File.open(check_filename,"a")

		valid_all_num=@alipay_transaction_detail.size
		valid_complete_num=0
		valid_succ_num=0
		valid_fail_num=0
		valid_rescue_num=0

		@alipay_transaction_detail.each do |element_detail|
			begin
				rd=ReconciliationDetail.init( xml_element_to_hash_alipay(element_detail) )
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

	def get_reconciliation_count()
		if @seller_email==Settings.alipay_transaction.seller_email_direct
			pid,secret=Settings.alipay_transaction.pid_direct,Settings.alipay_transaction.secret_direct
		else
			pid,secret=Settings.alipay_transaction.pid,Settings.alipay_transaction.secret
		end

		options = {
			# 'export_trade_account_report'
			'service' => self.service,
			'partner' => pid,
			'_input_charset' => 'utf-8',
			'gmt_create_start' => self.gmt_start_time,
			'gmt_create_end' => self.gmt_end_time
		}

		reconciliation_url="#{Settings.alipay_transaction.alipay_transaction_api_ur}?#{query_string(options,secret)}"
		Rails.logger.info("#{reconciliation_url}")
		response=method_url_response("get",reconciliation_url,true,{})
		#Rails.logger.info(response.body)

		# "#{self.service}</br>#{reconciliation_url}</br></br>#{response.body}"
	end

	def get_reconciliation_detail()
		if @seller_email==Settings.alipay_transaction.seller_email_direct
			pid,secret=Settings.alipay_transaction.pid_direct,Settings.alipay_transaction.secret_direct
		else
			pid,secret=Settings.alipay_transaction.pid,Settings.alipay_transaction.secret
		end

		options = {
			# 'account.page.query'
			'service' => self.service,
			'partner' => pid,
			'_input_charset' => 'utf-8',
			'page_no' => self.page_no,
			'gmt_start_time' => self.gmt_start_time,
			'gmt_end_time' => self.gmt_end_time,
			'page_size' => self.page_size
		}

		reconciliation_url="#{Settings.alipay_transaction.alipay_transaction_api_ur}?#{query_string(options,secret)}"
		Rails.logger.info("#{reconciliation_url}")
		response=method_url_response("get",reconciliation_url,true,{})

		# Rails.logger.info(response.body)
		doc = Nokogiri::XML(response.body.force_encoding("UTF-8"))

		is_succ=doc.xpath("//alipay/is_success").first.text
		if(is_succ=="T")
			@alipay_transaction_detail=doc.xpath("//alipay/response/account_page_query_result/account_log_list/AccountQueryAccountLogVO")
			true if doc.xpath("//alipay/response/account_page_query_result/has_next_page").text=="T"
			# Rails.logger.info(alipay_transaction_detail)
			# "#{self.service}</br>#{reconciliation_url}</br></br>#{response.body}"
		else
			@alipay_transaction_detail=""
			Rails.logger.warn("failure:"+doc.xpath("//alipay/error").first.text)
			false
		end
	end

	private
		def xml_element_to_hash_alipay(element)
			hash_alipay={
				'payway'=>'alipay',
				'paytype'=>'transaction',
				'batch_id'=>@reconciliation_date+"_"+sprintf("%03d",@batch_id),
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT'],
			}

			child=element.child
			while child
				case child.name
				when "trans_date" then 
					hash_alipay["timestamp"]=child.text
					hash_alipay["transaction_date"]=child.text[0,10]
				when "sub_trans_code_msg" then hash_alipay["transaction_type"]=child.text
				when "trans_code_msg" then hash_alipay["transaction_type"]=child.text+" - "+hash_alipay["transaction_type"]
				when "trade_no" then hash_alipay["transactionid"]=child.text
				when "total_fee" then hash_alipay["amt"]=child.text.to_f
				when "currency" then 
					if (child.text=="156")
						hash_alipay["currencycode"]="RMB"
					else
						hash_alipay["currencycode"]=child.text
					end
				when "service_fee" then hash_alipay["feeamt"]=child.text.to_f
				else
					Rails.logger.warn("Analytical failure - child : #{child}")
				end

				child=child.next
			end
			hash_alipay["netamt"]=hash_alipay["amt"]-hash_alipay["feeamt"]
			hash_alipay["transaction_status"]="succ" #? all is succ

			hash_alipay
		end
end