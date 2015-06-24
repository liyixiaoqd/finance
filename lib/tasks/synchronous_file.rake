desc "财务对账rake任务 - 产生每日与外部系统对接文件"

namespace :sync_file do
	desc "生成同步文件"
	task :product,[:arg1,:arg2] =>[:environment] do|t,args|
		@interface_logger = Logger.new("log/sync_file.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}

		@beg = args[:arg1]
		@end = args[:arg2]
		if @beg.blank? || @end.blank?
			@beg=OnlinePay.current_time_format("%Y-%m-%d",-1)
			@end=OnlinePay.current_time_format("%Y-%m-%d",1)
		end
		@interface_logger.info("=================== sync_file start:#{@beg} -- #{@end}===================")
		Rake::Task["sync_file:finance_water"].invoke
		@interface_logger.info("---------------------------------")
		Rake::Task["sync_file:finance_invoice"].invoke
		@interface_logger.info("---------------------------------")
		@interface_logger.info("=================== sync_file end:#{@beg} -- #{@end}===================\n\n\n\n")
	end

	desc "生成客户流水文件"
	task :finance_water =>[:environment] do 
		@interface_logger.info("user_finance_water sync file proc start")

		begin
			system_list=["mypost4u","quaie"]
			file_hash={}
			filepath=Settings.sync_file.rootpath+Settings.sync_file.finance_water+"/"
			system_list.each do |s|
				filename=filepath+s+"_user_finance_water_"+OnlinePay.current_time_format("%Y%m%d%H%M%S")+".txt"
				file_hash[s]=open(filename,"a")
				@interface_logger.info("filename: #{filename}")
			end

			split="|&|"
			FinanceWater.where("channel='finance_web' and operdate>=\"#{@beg}\" and operdate<\"#{@end}\"").each do |finance|
				if file_hash[finance.system].blank?
					@interface_logger.info("WARN: no system:#{finance.system} include? #{finance.id}")
					next
				end

				outline=[finance.userid,finance.watertype,finance.symbol,finance.old_amount,finance.amount,finance.new_amount,finance.reason,finance.operdate]
				file_hash[finance.system].puts "#{outline.join(split)}"
			end

			system_list.each do |s|
				file_hash[s].close
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
		@interface_logger.info("finance_invoice sync file proc start")

		begin
			system_list=["mypost4u","quaie"]
			file_hash={}
			filepath=Settings.sync_file.rootpath+Settings.sync_file.finance_invoice+"/"
			system_list.each do |s|
				filename=filepath+s+"_finance_invoice_"+OnlinePay.current_time_format("%Y%m%d%H%M%S")+".txt"
				file_hash[s]=open(filename,"a")
				@interface_logger.info("filename: #{filename}")
			end

			split="|&|"
			ReconciliationDetail.includes(:online_pay).where("confirm_flag=\"#{ReconciliationDetail::CONFIRM_FLAG['SUCC']}\" and confirm_date>=\"#{@beg}\" and confirm_date<\"#{@end}\"").each do |rd|
				if rd.online_pay.blank? || rd.online_pay.order_no.blank?
					@interface_logger.info("WARN:order_no is nil? #{rd.id}")
					next
				end

				if file_hash[rd.online_pay.system].blank?
					@interface_logger.info("WARN: no system:#{rd.online_pay.system} include? #{rd.id}")
					next
				end

				outline=[rd.online_pay.order_no,rd.confirm_date.to_s[0,10]]
				file_hash[rd.online_pay.system].puts "#{outline.join(split)}"
			end

			system_list.each do |s|
				file_hash[s].close
			end
		rescue => e
			@interface_logger.info("ERROR: finance_invoice sync file proc failure #{e.message}")
			system_list.each do |s|
				File.delete file_hash[s] unless file_hash[s].blank?
			end
		end
		@interface_logger.info("finance_invoice sync file proc end")
	end
end