desc "支付异步失败重发任务"

namespace :async_notice do
	desc "失败重发任务"
	task :online_pay,[:arg1,:arg2] =>[:environment] do|t,args|
		@interface_logger = Logger.new("log/async_notice.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}

		@interface_logger.info("=================== async_notice online_pay start===================")
		ops=OnlinePay.where("status='failure_notify_third'")
		@interface_logger.info("re notice: #{ops.size} ")
		ops.each do |op|
			begin
				ret_hash={
					'trade_no'=>op.trade_no,
					'status'=>"",
					'status_reason'=>op.callback_status,
					'amount'=>op.amount,
					'payway'=>op.payway,
					'paytype'=>op.paytype,
					'water_no'=>'',
					'sign'=>Digest::MD5.hexdigest("#{op.trade_no}#{Settings.authenticate.signkey}")		
				}

				#获取产生的财务流水ID
				if op.system=="quaie"
					fws=FinanceWater.where(user_id: op.user_id,operator: "system_submit",symbol: "Add",amount: op.amount).order("created_at desc")
					if fws.present?
						ret_hash['water_no']=fws[0].id
					end
				end

				ret_hash['status']='success_notify'

				@interface_logger.info("#{op.order_no} recall hash:#{ret_hash}")
				op.with_lock do
					redirect_notify_url=OnlinePay.redirect_url_replace("post",op.notification_url)
					response=op.method_url_response("post",redirect_notify_url,false,ret_hash)
					if response.code=="200" && JSON.parse(response.body)['status']=="success"
						op.set_status!("success_notify","")
						op.reconciliation_detail.update_attributes!({:online_pay_status=>op.status}) unless op.reconciliation_detail.blank? 
					else
						op.set_status!("failure_notify_third","recall info[#{response.code}:#{response.body}]")
					end
					op.save!()
				end
				@interface_logger.info("#{op.order_no} recall info:#{op.status} #{op.reason}")
			rescue => e
				@interface_logger.info("#{op.order_no} recall error:#{e.message}")
			end
		end
		@interface_logger.info("=================== async_notice online_pay end===================")
	end
end