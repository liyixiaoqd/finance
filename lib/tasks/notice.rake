desc "产生待处理任务批处理"

namespace :notice do
	desc "电商充值"
	task :merchant_recharge =>[:environment] do 
		logger=init_logger("merchant_recharge.log")
		diffday=BasicData.get_value("00B","001","notice","").to_i
		FinanceWater.unscoped().includes(:user).
			where("datediff(now(),finance_waters.operdate)>=? \
				and finance_waters.watertype='e_cash' \
				and finance_waters.confirm_flag='0' \
				and users.user_type='merchant'",diffday).references(:user).each do |fw|
			begin
				notice=fw.set_notice_by_merchant('recharge')
				if notice.blank?
					logger.info("#{fw.user.username},#{fw.id} - 未产生充值待处理任务,已存在未处理记录?")
				else
					notice.save!()
					logger.info("#{fw.user.username},#{fw.id} - 产生充值待处理任务")
				end
			rescue=>e
				logger.warn("#{fw.user.username},#{fw.id} - 产生充值待处理任务异常:#{e.message}")
			end
		end
		logger.info("NOTICE::MERCHANT_RECHARGE END")
		logger.close
	end

	def init_logger(filename)
		interface_logger = Logger.new("log/#{filename}")
		interface_logger.level=Logger::INFO
		interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}

		interface_logger.info("NOTICE::MERCHANT_RECHARGE START")
		interface_logger
	end
end