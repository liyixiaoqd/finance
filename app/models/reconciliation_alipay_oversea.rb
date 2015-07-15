class ReconciliationAlipayOversea
	include AlipayDetailable
	include PayDetailable
	attr_accessor :service,:start_date,:end_date

	WARN_FILE_PATH="check_file/finance_reconciliation/alipay_oversea"

	def initialize(service,start_date="",end_date="")
		@service=service

		post_day=BasicData.get_value("00A","001","alipay","oversea").to_i
		if(start_date.blank?)
			@start_date=current_time_format("%Y%m%d",0-post_day)
		else
			@start_date=start_date
		end

		if(end_date.blank?)
			@end_date=@start_date
		else
			@end_date=end_date
		end
		@alipay_oversea_detail=[]
		@reconciliation_date=current_time_format("%Y%m%d",0)
		@batch_id=1	# 001
	end

	#call interface
	def get_reconciliation
		options = {
			'service' => self.service,
			'partner' => Settings.alipay_oversea.pid,
			'start_date' => self.start_date,
			'end_date' => self.end_date
		}	

		reconciliation_url="#{Settings.alipay_oversea.alipay_oversea_api_ur}?#{query_string(options,Settings.alipay_oversea.secret)}"
		Rails.logger.info("#{reconciliation_url}")
		response=method_url_response("get",reconciliation_url,true,{})

		if(response.body[0]=="<" || response.body[0,20]=="File download failed")
			Rails.logger.warn("failure:"+response.body)
		else
			@alipay_oversea_detail=response.body.split("\r\n")
		end
	end

	#call  get_reconciliation and valid_reconciliation
	def finance_reconciliation()
		get_reconciliation()
		message="#{@start_date} - #{@end_date} </br> #{valid_reconciliation()}"
	end

	#insert record!
	def valid_reconciliation
		if @alipay_oversea_detail.blank?
			return "response Analytical failure"
		end

		check_filename=WARN_FILE_PATH+"/alipay_oversea_finance_reconciliation_warn_"+@reconciliation_date+".log"
		Rails.logger.info("check_filename:#{check_filename}")
		check_file=File.open(check_filename,"a")

		valid_all_num=@alipay_oversea_detail.size
		valid_complete_num=0
		valid_succ_num=0
		valid_fail_num=0
		valid_rescue_num=0

		@alipay_oversea_detail.each do |oversea_detail|
			begin
				rd=ReconciliationDetail.init( array_to_hash_alipay(oversea_detail) )
				rd.valid_and_save!()				

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

	private 
		def array_to_hash_alipay(oversea_detail)
			# TIME140147826|32.20|EUR|20150405000123|20150407141217|P|0.39|L|???TIME140147826???????
			array_detail=oversea_detail.split("|")

			{
				'timestamp'=>array_detail[3],
				'transaction_type'=>array_detail[5],
				'transactionid'=>array_detail[0],
				'transaction_status'=>array_detail[7],
				'amt'=>array_detail[1].to_f,
				#'currencycode'=>array_detail[2],  所有支付宝都显示RMB
				'currencycode'=>'RMB',
				'feeamt'=>array_detail[6].to_f,
				'netamt'=>array_detail[1].to_f - array_detail[6].to_f,
				'payway'=>'alipay',
				'paytype'=>'oversea',
				'transaction_date'=>array_detail[3][0,4]+"-"+array_detail[3][4,2]+"-"+array_detail[3][6,2],
				'batch_id'=>@reconciliation_date+"_"+sprintf("%03d",@batch_id),
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT']
			}
		end
end