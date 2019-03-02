desc "系统重试交易"

namespace :callqueue do
	desc "重试交易-第三方系统判断交易是否成功"
	task :online_pay_is_succ=>[:environment] do 
		@interface_logger = Logger.new("log/call_queue.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}
		@interface_logger.info("callqueue online_pay_is_succ start")

		CallQueue.polling("online_pay_is_succ")
		
		@interface_logger.info("callqueue  online_pay_is_succ end")
	end

	desc "获取支付包裹的物流信息及推送"
	task :track_info_proc=>[:environment] do 
		@interface_logger = Logger.new("log/track_info_proc.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}
		@interface_logger.info("callqueue track_info_proc start")

		["mypost4u", "quaie"].each do |system|
			CallQueue.oceanpayment_push_task_get_info(system)
			CallQueue.oceanpayment_push_task_push(system)
		end
		
		@interface_logger.info("callqueue  track_info_proc end")
	end

	desc "冻结代金券取消"
	task :cash_coupon_cancel=>[:environment] do 
		@interface_logger = Logger.new("log/cash_coupon_cancel.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}
		@interface_logger.info("callqueue cash_coupon_cancel start")

		CashCouponDetail.cron_cancel_state()
		
		@interface_logger.info("callqueue cash_coupon_cancel end")
	end
end

