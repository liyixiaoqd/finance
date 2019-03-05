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
	task :cash_coupon_check=>[:environment] do 
		@interface_logger = Logger.new("log/cash_coupon_check.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}
		@interface_logger.info("===============================")
		@interface_logger.info("callqueue cash_coupon_check start")

		ccd_abnormal = CashCouponDetail.where(state: CashCouponDetail::ABNORMAL).count
		@interface_logger.info("\n-----\nCashCouponDetail Abnormal number: [#{ccd_abnormal}]\n-----")

		check_normal, check_abnormal = 0, 0
		CashCoupon.all.each do |cc|
			warn_flag = false
			ccd_frozen = 0 
			ccd_use = 0
			CashCouponDetail.where(cash_coupon_id: cc.id).each do |ccd|
				if ccd.state == CashCouponDetail::FROZEN
					ccd_frozen += ccd.quantity
				elsif ccd.state == CashCouponDetail::USE
					ccd_use += ccd.quantity
				end
			end

			if cc.fr_quantity != ccd_frozen
				@interface_logger.info("CashCoupon[#{cc.id}] fr_quantity abnormal: [#{cc.fr_quantity}] <-> [#{ccd_frozen}]")
				warn_flag = true
			end

			if cc.av_quantity != cc.quantity - ccd_use - ccd_frozen
				@interface_logger.info("CashCoupon[#{cc.id}] av_quantity abnormal: [#{cc.quantity} - #{cc.av_quantity}] <-> [#{ccd_use} + #{ccd_frozen}]")
				warn_flag = true
			end

			if warn_flag
				check_abnormal += 1
			else
				check_normal += 1
			end
		end
		
		@interface_logger.info("callqueue cash_coupon_check end ; normal[#{check_normal}], abnormal[#{check_abnormal}]")
		@interface_logger.info("===============================\n")
	end
end

