class ReconciliationSofort
	include AlipayDetailable
	include PayDetailable

	WARN_FILE_PATH="check_file/finance_reconciliation/sofort"
	COLUMN_NUM=35
	SKIP_LINE=1

	def valid_reconciliation(sofort_array)
		"response Analytical failure" if @array.blank?

		reconciliation_date=current_time_format("%Y%m%d",0)
		batch_id=1

		check_filename=WARN_FILE_PATH+"/paypal_finance_reconciliation_warn_"+reconciliation_date+".log"
		Rails.logger.info("check_filename:#{check_filename}")
		check_file=File.open(check_filename,"a")

		valid_all_num=sofort_array.size-SKIP_LINE
		valid_complete_num=0
		valid_succ_num=0
		valid_fail_num=0
		valid_rescue_num=0

		skip_num=0

		sofort_array.each do |sofort_detail|
			begin
				if skip_num < SKIP_LINE
					skip_num=skip_num+1
					next
				end

				rd=ReconciliationDetail.init( array_to_hash_sofort(sofort_detail,reconciliation_date,batch_id) )
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
		def array_to_hash_sofort(sofort_detail,reconciliation_date,batch_id)
			raise "Row Analytical failure: size #{sofort_detail.size} !=#{COLUMN_NUM}" if sofort_detail.size!=COLUMN_NUM

			{
				'timestamp'=>sofort_detail[33],
				'name'=>sofort_detail[4],
				'transactionid'=>sofort_detail[2],
				'transaction_status'=>sofort_detail[28],
				'amt'=>sofort_detail[18].to_f,
				'currencycode'=>sofort_detail[20],
				'feeamt'=>sofort_detail[30].to_f,
				'netamt'=>sofort_detail[18].to_f - sofort_detail[30].to_f,
				'payway'=>'sofort',
				'paytype'=>'',
				'transaction_date'=>reconciliation_date,
				'batch_id'=>reconciliation_date+"_"+sprintf("%03d",batch_id),
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT']
			}
		end
end