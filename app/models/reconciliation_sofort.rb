require 'roo'

class ReconciliationSofort
	include AlipayDetailable
	include PayDetailable

	WARN_FILE_PATH="check_file/finance_reconciliation/sofort"
	COLUMN_NUM=35
	SKIP_LINE=1

	def valid_reconciliation(sofort_array)
		"response Analytical failure" if @array.blank?
		errmsg=""
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
		valid_nosys_num=0

		skip_num=0
		i=0
		sofort_array.each do |sofort_detail|
			begin
				i=i+1
				if skip_num < SKIP_LINE
					skip_num=skip_num+1
					next
				end

				rd=ReconciliationDetail.init( array_to_hash_sofort(sofort_detail,reconciliation_date,batch_id) )
				rd.valid_and_save!()
			
				valid_complete_num=valid_complete_num+1
				if(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['NON_SYSTEM'])
					valid_nosys_num=valid_nosys_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'])
					valid_fail_num=valid_fail_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'])
					valid_succ_num=valid_succ_num+1
				end
			rescue => e
				check_file << "#{rd.warn_to_file(e.message)}\n" unless rd.blank?
				Rails.logger.info(e.message)

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
				valid_rescue_num=valid_rescue_num+1
			end
		end
		check_file.close

		# "#{reconciliation_date} - #{reconciliation_date} <br> batch_id [ #{@batch_id} ] : </br> {all_num:#{valid_all_num} = complete_num:#{valid_complete_num} + rescue_num:#{valid_rescue_num}</br> complete_num:#{valid_complete_num} = succ_num:#{valid_succ_num} + fail_num:#{valid_fail_num} }</br>"
		outmsg="文件总比数:#{valid_all_num},导入成功比数:#{valid_complete_num},异常比数:#{valid_rescue_num} ; 
			   对账成功比数:#{valid_succ_num},对账失败比数:#{valid_fail_num},非系统记录比数:#{valid_nosys_num}"
	end

	def valid_reconciliation_by_country(country,filename)
		skip_num=0
		sheet_num=0
		if country=="de"
			skip_num=5
			sheet_num=0
		elsif country=="nl"
			skip_num=2
			sheet_num=0
		elsif country=="at"
			skip_num=3
			sheet_num=2
		else
			raise "不支持的导入格式:#{country}"
		end

		errmsg=""
		xlsx=Roo::Spreadsheet.open(filename,extension: filename.to_s.split(".").last.to_sym)
		i=0
		valid_all_num=0
		valid_complete_num=0
		valid_succ_num=0
		valid_fail_num=0
		valid_rescue_num=0
		valid_nosys_num=0

		xlsx.sheet(sheet_num).each do |row|
			i =i+1
			next if i<skip_num
			begin
				valid_all_num=valid_all_num+1

				rd=ReconciliationDetail.init( DE_BOC_Bank_to_hash_sofort(row,i) ) if country=="de"
				rd=ReconciliationDetail.init( NL_ABN_Bank_to_hash_sofort(row,i) ) if country=="nl"
				rd=ReconciliationDetail.init( AT_SAT_Bank_to_hash_sofort(row,i) ) if country=="at"
				rd.valid_and_save!()

				
				valid_complete_num=valid_complete_num+1
				if(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['NON_SYSTEM'])
					valid_nosys_num=valid_nosys_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL'])
					valid_fail_num=valid_fail_num+1
				elsif(rd.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'])
					valid_succ_num=valid_succ_num+1
				end
			rescue => e
				Rails.logger.info("sofort对账异常:"+e.message)

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

				valid_rescue_num=valid_rescue_num+1
			end
		end

		outmsg="文件总比数:#{valid_all_num},导入成功比数:#{valid_complete_num},异常比数:#{valid_rescue_num} ; 
			   对账成功比数:#{valid_succ_num},对账失败比数:#{valid_fail_num},非系统记录比数:#{valid_nosys_num}"
		
		if errmsg.length>200
			Rails.logger.info("full errmsg:#{errmsg}")
			errmsg=errmsg[0,200]+"..."
		end
		[outmsg,errmsg]
	end

	def merchant_cash_in_proc(country,filename)
		sheet_num=0
		skip_num=0
		if country=="de_at"
			skip_num=3
			sheet_num=2
		elsif country=="nl"
		elsif country=="en"
			skip_num=5
			sheet_num=0
		else
			raise "不支持的导入格式:#{country}"
		end

		errmsg=""
		xlsx=Roo::Spreadsheet.open(filename,extension: filename.to_s.split(".").last.to_sym)

		i=0
		valid_all_num=0
		valid_succ_num=0
		valid_rescue_num=0

		xlsx.sheet(sheet_num).each do |row|
			i =i+1
			next if i<skip_num
			begin
				valid_all_num=valid_all_num+1

				userid,amount,operdate=MERCHANT_EN_CASH_IN_BANK_get_field(row,i) if country=="en"
				userid,amount,operdate=MERCHANT_DE_AT_CASH_IN_BANK_get_field(row,i) if country=="de_at"

				fw=get_fw_merchant_cash_in(userid,amount,operdate,i)

				if fw.blank?
					next
				end

				fw.update_attributes!({'confirm_flag'=>'1'})
				valid_succ_num=valid_succ_num+1
			rescue => e
				Rails.logger.info("交易记录处理异常:"+e.message)

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

				valid_rescue_num=valid_rescue_num+1
			end
		end

		outmsg="文件总比数:#{valid_all_num},匹配成功比数:#{valid_succ_num},异常比数:#{valid_rescue_num} "
		
		if errmsg.length>200
			Rails.logger.info("full errmsg:#{errmsg}")
			errmsg=errmsg[0,200]+"..."
		end
		[outmsg,errmsg]
	end

	private 
		def array_to_hash_sofort(sofort_detail,reconciliation_date,batch_id)
			raise "Row Analytical failure: size #{sofort_detail.size} !=#{COLUMN_NUM}" if sofort_detail.size!=COLUMN_NUM

			{
				'timestamp'=>sofort_detail[33],
				'name'=>sofort_detail[4],
				'order_no'=>sofort_detail[2],
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

		def DE_BOC_Bank_to_hash_sofort(row,i)
			sofort_detail={
				'transaction_status'=>'SUCC',
				'payway'=>'sofort',
				'feeamt'=>0.0,
				'paytype'=>'',
				'transaction_date'=>'',
				'batch_id'=>"upload_file_de",
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT'],
				'order_no'=>''
			}
			j=0
			row.each do |col|
				j=j+1

				next unless j==3 || j==5 || j==6 || j==8 || j==10
				col.gsub!(/\t$/,"") if col.class.to_s=="String"
				sofort_detail["amt"],sofort_detail['netamt']=col,col if j==3
				sofort_detail["currencycode"]=col if j==5
				if j==6
					col=col.to_s
					sofort_detail['transaction_date']=col[0,4]+"-"+col[5,2]+"-"+col[8,2] unless col.blank?
					sofort_detail['timestamp']=col
				end
				sofort_detail['name']=col if j==8
				sofort_detail['order_no']=col if j==10
				# next unless j==16 || j==15 || j==13 || j==14 || j==26 || j==7
				# col.gsub!(/\t$/,"") if col.class.to_s=="String"
				# sofort_detail["amt"],sofort_detail['netamt']=col,col if j==16
				# sofort_detail["currencycode"]=col if j==15
				# if j==13
				# 	col=col.to_s
				# 	sofort_detail['transaction_date']=col[0,4]+"-"+col[4,2]+"-"+col[6,2] unless col.blank?
				# end
				# sofort_detail['timestamp']=sofort_detail['transaction_date']+" "+col if j==14
				# sofort_detail['name']=col if j==7
				# sofort_detail['order_no']=col if j==26
			end
			
			if sofort_detail['order_no'].blank?
				raise "第#{i}行:对账标识(订单号)为空!"
			end
			if sofort_detail['transaction_date'].blank?
				raise "第#{i}行:对账日期(第6列)为空!"
			end
			sofort_detail
		end

		def NL_ABN_Bank_to_hash_sofort(row,i)
			sofort_detail={
				'transaction_status'=>'SUCC',
				'payway'=>'sofort',
				'paytype'=>'',
				'transaction_date'=>'',
				'batch_id'=>"upload_file_nl",
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT'],
				'order_no'=>''
			}

			j=0
			row.each do |col|
				j=j+1
				next unless j==2 || j==3 || j==7 || j==8 || j==4
				col.gsub!(/\t$/,"") if col.class.to_s=="String"
				sofort_detail["currencycode"]=col if j==2
				if j==3 && col.present?
					col=col.to_s
					sofort_detail['timestamp']=col[0,4]+"-"+col[4,2]+"-"+col[6,2]
				end
				if j==4 && col.present?
					col=col.to_s
					sofort_detail['transaction_date']=col[0,4]+"-"+col[4,2]+"-"+col[6,2]
				end
				sofort_detail["amt"],sofort_detail['netamt']=col,col if j==7
				if j==8
					#sample : 
					#/TRTP/SEPA OVERBOEKING/IBAN/NL40ABNA0526989491/BIC/ABNANL2A/NAME/Z SHI/REMI/TIME140178795/EREF/NOTPROVIDED
					parttern_match=/\/REMI\/(.*?)\//.match(col)
					sofort_detail['order_no']=parttern_match[1] unless parttern_match.blank?
				end
			end
			#Rails.logger.info("timestamp:#{sofort_detail['timestamp']}")

			if sofort_detail['order_no'].blank?
				raise "第#{i}行:对账标识(订单号)获取失败!"
			end
			if sofort_detail['transaction_date'].blank?
				raise "第#{i}行:对账日期(第4列)错误!"
			end
			sofort_detail
		end

		def AT_SAT_Bank_to_hash_sofort(row,i)
			sofort_detail={
				'transaction_status'=>'SUCC',
				'payway'=>'sofort',
				'feeamt'=>0.0,
				'paytype'=>'',
				'transaction_date'=>'',
				'batch_id'=>"upload_file_at",
				'reconciliation_flag'=>ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['INIT'],
				'order_no'=>''
			}
			j=0
			row.each do |col|
				j=j+1
				next unless j==6 || j==8 || j==9 || j==26 || j==15
				col.gsub!(/\t$/,"") if col.class.to_s=="String"
				if j==8
					# 样例数据 小数点使用 逗号
					if col.class.to_s=="String"
						col_arr=col.split(",")
						if col_arr.size>1 
							col=""
							tmp=1
							col_arr.each do |c|
								if tmp==col_arr.size
									col+="."+c
								else
									col+=c
								end

								tmp+=1
							end
							col=col.to_f
						end
					end
					sofort_detail["amt"],sofort_detail['netamt']=col,col
				end
				sofort_detail["currencycode"]=col if j==9
				if j==6
					sofort_detail['timestamp']=col[6,4]+"-"+col[3,2]+"-"+col[0,2] 
					sofort_detail['transaction_date']=col[6,4]+"-"+col[3,2]+"-"+col[0,2] 
				end
				sofort_detail['name']=col if j==26
				if j==15
					sofort_detail['order_no']=col.split("+")[2].rstrip if col.split("+").size>2
				end
			end
			if sofort_detail['order_no'].blank?
				raise "第#{i}行:对账标识(订单号)为空!"
			end
			if sofort_detail['transaction_date'].blank?
				raise "第#{i}行:对账日期(第6列)为空!"
			end
			sofort_detail
		end

		def MERCHANT_EN_CASH_IN_BANK_get_field(row,i)
			userid=nil 
			amount=0.0
			operdate=nil

			j=0
			row.each do |col|
				j=j+1
				next unless j==3 || j==6|| j==10
				col.gsub!(/\t$/,"") if col.class.to_s=="String"
				amount=col if j==3
				operdate=col[0,10].gsub("/","-") if j==6
				if j==10
					if col.present? && col[0]=="@"
						userid=col.sub("@","")
					end
				end
			end

			[userid,amount,operdate]
		end

		def MERCHANT_DE_AT_CASH_IN_BANK_get_field(row,i)
			userid=nil 
			amount=0.0
			operdate=nil

			j=0
			row.each do |col|
				j=j+1
				next unless j==15 || j==8|| j==6
				operdate=col[6,4]+"-"+col[3,2]+"-"+col[0,2]  if j==6
				if j==8
					# 样例数据 小数点使用 逗号
					if col.class.to_s=="String"
						col_arr=col.split(",")
						if col_arr.size>1 
							col=""
							tmp=1
							col_arr.each do |c|
								if tmp==col_arr.size
									col+="."+c
								else
									col+=c
								end

								tmp+=1
							end
							col=col.to_f
						end
					end
					amount=col
				end
				if j==15
					if col.present? && col[0]=="@"
						userid=col.sub("@","")
					end
				end
			end

			[userid,amount,operdate]
		end

		def get_fw_merchant_cash_in(userid,amount,operdate,i)
			fw=nil
			return fw if userid.blank?

			users=User.where("userid=? and user_type='merchant'",userid)
			if users.blank?
				return fw
			end

			 if users.size>1
			 	raise "第#{i}行:#{userid}存在多条记录,请确认!"
			 end

			 fws=FinanceWater.where("user_id=? and watertype='e_cash' \
			 	and symbol='Add' and confirm_flag='0' and amount=? \ 
			 	and left(operdate,10)=? ",users[0].id,amount,operdate)

			if fws.blank?
				raise "第#{i}行:无#{userid}充值记录-[#{amount}]"
			else
				fw=fws[0]
			end

			fw
		end
end