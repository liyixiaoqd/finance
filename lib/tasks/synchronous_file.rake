desc "财务对账rake任务 - 产生每日与外部系统对接文件"

namespace :sync_file do
	desc "生成同步文件"
	task :product,[:arg1,:arg2,:arg3] =>[:environment] do|t,args|
		init_interface_logger

		filetype = args[:arg1]
		@beg = args[:arg2]
		@end = args[:arg3]
		if @beg.blank? || @end.blank?
			@beg=OnlinePay.current_time_format("%Y-%m-%d",-1)
			@end=OnlinePay.current_time_format("%Y-%m-%d",1)
		end

		@interface_logger.info("=================== sync_file start:[#{filetype}] #{@beg} -- #{@end}===================")
		if filetype=="finance_water"
			Rake::Task["sync_file:finance_water"].invoke
			@interface_logger.info("---------------------------------")
		elsif filetype=="finance_invoice"
			Rake::Task["sync_file:finance_invoice"].invoke
			@interface_logger.info("---------------------------------")
		end
		@interface_logger.info("=================== sync_file end:[#{filetype}] #{@beg} -- #{@end}===================\n\n\n\n")
	end

	desc "生成客户流水文件"
	task :finance_water =>[:environment] do 
		init_interface_logger
		@interface_logger.info("user_finance_water sync file proc start")

		begin
			system_list=["mypost4u","quaie"]
			file_hash={}
			filepath=Settings.sync_file.rootpath+Settings.sync_file.finance_water+"/"
			system_list.each do |s|
				begin
					Dir.mkdir(filepath+s+"_"+OnlinePay.current_time_format("%Y%m%d"))
				rescue=>e
				end
				filename=filepath+s+"_"+OnlinePay.current_time_format("%Y%m%d")+"/"+s+"_user_finance_water_"+OnlinePay.current_time_format("%Y%m%d%H%M%S")+".txt"
				file_hash[s]=open(filename,"a")
				@interface_logger.info("filename: #{filename}")
			end

			split="|&|"
			FinanceWater.unscoped.where("channel='finance_web' and operdate>=\"#{@beg}\" and operdate<\"#{@end}\"").order("operdate asc").each do |finance|
				if file_hash[finance.system].blank?
					@interface_logger.info("WARN: no system:#{finance.system} include? #{finance.id}")
					next
				end

				outline=[finance.userid,finance.watertype,finance.symbol,finance.old_amount,finance.amount,finance.new_amount,finance.reason,finance.operdate,finance.id]
				file_hash[finance.system].puts "#{outline.join(split)}"
			end

			system_list.each do |s|
				file_hash[s].close
				File.open("#{file_hash[s].to_path}.ok", "w")  do  |file|
					file.puts("ok")
					file.close
    				end
			end
		rescue => e
			@interface_logger.info("ERROR: user_finance_water sync file proc failure #{e.message}")
			system_list.each do |s|
				File.delete file_hash[s] unless file_hash[s].blank?
			end
		end
		@interface_logger.info("user_finance_water sync file proc end")
	end

	desc "生成财务确认文件"
	task :finance_invoice =>[:environment] do 
		init_interface_logger
		@interface_logger.info("finance_invoice sync file proc start")


		fail_msg=""
		fail_num=0	
		begin
			system_list=["mypost4u","quaie"]
			file_hash={}
			filepath=Settings.sync_file.rootpath+Settings.sync_file.finance_invoice+"/"
			system_list.each do |s|
				begin
					Dir.mkdir(filepath+s+"_"+OnlinePay.current_time_format("%Y%m%d"))
				rescue=>e
				end
				filename=filepath+s+"_"+OnlinePay.current_time_format("%Y%m%d")+"/"+s+"_finance_invoice_"+OnlinePay.current_time_format("%Y%m%d%H%M%S")+".txt"
				file_hash[s]=open(filename,"a")
				@interface_logger.info("filename: #{filename}")
			end

			split="|&|"
			ReconciliationDetail.unscoped.includes(:online_pay).where("confirm_flag=\"#{ReconciliationDetail::CONFIRM_FLAG['SUCC']}\" and (invoice_date is null or invoice_date='') ").order("transaction_date asc").each do |rd|
				ActiveRecord::Base.transaction do
					begin
						@interface_logger.info("transactionid:[#{rd.transactionid}],[#{rd.system}] start")
						if rd.system.blank? || file_hash[rd.system].blank?
							raise "no system:[#{rd.system}] include,ID:#{rd.id}"
						end
						#@interface_logger.info("file_hash[#{rd.system}]")

						#退订单中包裹情况
						if rd.batch_id=="refund_parcel"
							order_no=rd.transactionid
						else
							order_no=rd.order_no
						end

						invoice_no = LockSequence.judge_system_and_get_invoice(rd)

						rd.update_attributes!({'invoice_date'=>@end,'invoice_no'=>invoice_no})
						@interface_logger.info("SUCC : #{rd.batch_id},#{order_no},#{invoice_no},#{@end}")

						outline=[order_no,rd.transaction_date.to_s,invoice_no]
						file_hash[rd.system].puts "#{outline.join(split)}"
					rescue=>e
						fail_num+=1
						if fail_msg.length<=1000
							fail_msg+="#{rd.id},"
						end
						rd.update_attributes({'reconciliation_describe'=>"invoice:#{e.message}"})
						@interface_logger.info("FAIL : [#{e.message}]")
					end
				end
			end

			system_list.each do |s|
				file_hash[s].close
				File.open("#{file_hash[s].to_path}.ok", "w")  do  |file|
					file.puts("ok")
					file.close
    				end
			end
		rescue => e
			@interface_logger.info("ERROR: finance_invoice sync file proc failure #{e.message}")
			system_list.each do |s|
				File.delete file_hash[s] unless file_hash[s].blank?
			end
		end


		if fail_num>0
			@interface_logger.info("file gen record fail_number: #{fail_num} and insert notice")
			notice=Notice.set_params_by_invoice(fail_num,fail_msg)
			notice.save
			if notice.errors.present?
				@interface_logger.info("insert notice error: #{notice.errors.full_messages}")
			end
		end
		@interface_logger.info("finance_invoice sync file proc end")
	end


	# 根据文件内容生成 支付数据与对账数据
	desc "第三方支付文件数据同步"
	# 样例数据:  
	# userid|&|payway|&|paytype   |&|amount|&|currency|&|order_no            |&|description|&|country|&|reconciliation_id    |&|order_type|&|pay_date
	# 25802 |&|wechat|&|mobile_pay|&|35.5  |&|RMB     |&|TM180502001137060950|&|parcel pay |&|de     |&|180502165621000050818|&|parcel    |&|2018-07-30 12:00:20
	task :third_payment =>[:environment] do
		init_interface_logger
		@interface_logger.info("third_payment sync file proc start")
		Adapter::ArrTransHash
			
		begin
			split = "|&|"
			arr_format = ["userid", "payway", "paytype", "amount", "currency", "order_no", \
				"description", "country", "reconciliation_id", "order_type", "null", "system"]

			filepath = Settings.sync_file.rootpath+Settings.sync_file.third_payment+"/"
			Dir.foreach(filepath) do |filename|
				begin
					@interface_logger.info("filename: #{filename}")
					next if filename.start_with?(".")
					raise "wrong file format" unless filename.end_with?("txt")
					f_system = filename.split("_")[0]

					raise "wrong file format" unless ["mypost4u", "quaie"].include?(f_system)

					index = 0
					File.open(filepath+filename, "r") do |file|
						while line = file.gets
							ActiveRecord::Base.transaction do 
								index += 1
								begin
									pay_arr = line.chomp.split(split)
									pay_arr << f_system
									ath_op = Adapter::ATHOnlinePaySF.new(arr_format)
									op = OnlinePay.new(ath_op.arr_to_hash(pay_arr))
									op.save()
									if op.errors.present?
										raise "#{op.errors.full_messages}"
									end
									rd = op.set_reconciliation
									rd.set_transaction_date!(pay_arr[10].strip)
									# is need to dui zhang 
									rd.set_flag_by_status_and_amount!()
									rd.save()
									if rd.errors.present?
										raise "#{rd.errors.full_messages}"
									end
									@interface_logger.info("proc op record #{filename}[#{index}] - succ")
								rescue=>e
									@interface_logger.info("proc #{filename}[#{index}] - #{line.chomp} failure #{e.message}")
									raise ActiveRecord::Rollback,"rollback!"
								end
							end
						end
					end

					File.rename(filepath+filename,filepath+filename+".end")
				rescue=>e
					@interface_logger.info("proc #{filename} failure #{e.message}")
				end
			end
		rescue=>e
			@interface_logger.info("ERROR: third_payment proc failure #{e.message}")
		end

		@interface_logger.info("third_payment sync file proc end")
	end

	def init_interface_logger
		if @interface_logger.blank?
			@interface_logger = Logger.new("log/sync_file.log")
			@interface_logger.level=Logger::INFO
			@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
			@interface_logger.formatter=proc{|severity,datetime,progname,msg|
				"[#{datetime}] :#{msg}\n"
			}
		end
	end
end