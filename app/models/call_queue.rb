class CallQueue < ActiveRecord::Base
	# t.string :callback_interface
	# t.string :reference_id
	# t.string :status
	# t.string :run_batch
	# t.datetime :last_callback_time
	# t.string :last_callback_result
	# t.integer :try_amount
	# t.integer :tried_amount
	#产生待处理任务:调用第三方支付系统,判断支付交易是否成功
	#暂时只用于paypal与sofort
	def self.online_pay_is_succ_record(online_pay_id)
		if CallQueue.find_by_callback_interface_and_reference_id("online_pay_is_succ",online_pay_id).blank?			
			cq=CallQueue.new
			cq.callback_interface="online_pay_is_succ"
			cq.reference_id=online_pay_id
			cq.status="init"
			cq.try_amount=1
			cq.tried_amount=0
			cq.run_batch=""
			cq.start_call_time=(Time.now.utc+5*60).to_s[0,19]	#5分钟后才允许调用 UTC

			unless cq.save
				Rails.logger.info("CallQueue save failure:#{cq.errors.full_messages}")
			end

			cq
		end
	end

	def online_pay_is_succ_set()
		update_attributes({:status=>"success",:last_callback_result=>"正常调用修改待处理任务状态"})
	end

	def self.polling(callback_interface,reference_id="")
		start_time=Time.now.utc.to_s[0,19]	
		batch=Time.now.strftime("%Y%m%d%H%M%S")
		where_condition={"callback_interface"=>callback_interface}
		unless reference_id.blank?
			where_condition["reference_id"]=reference_id
		end

		cqs=CallQueue.where(where_condition).where("status in ('init') and start_call_time<='#{start_time}'")
		cqs.where(run_batch: "").update_all(run_batch: batch)
		cqs.where(run_batch: batch).each do |cq|
			ActiveRecord::Base.transaction do
				begin
					online_pay=OnlinePay.lock.find(cq.reference_id)
					if online_pay.blank?
						raise "no online_pay record #{cq.reference_id} get!!"
					end

					cq.run_batch=""
					if online_pay.is_success_self?
						cq.online_pay_is_succ_set()
						next
					end

					unless online_pay.payway=="paypal"
						cq.status="wait"
						cq.last_callback_result="尚不支持交易#{online_pay.payway}判断是否成功"
						cq.save
						next
					end

					pay_detail=OnlinePay.get_instance_pay_detail(online_pay)

					cq.tried_amount+=1
					cq.last_callback_time=Time.now
					flag,message,reconciliation_id,callback_status=pay_detail.is_succ_pay_by_call?(online_pay,cq.start_call_time)

					if flag
						online_pay.set_status!("success_notify","")
						online_pay.reconciliation_id=reconciliation_id
						online_pay.save!()
						online_pay.set_reconciliation.save!()

						ret_hash=init_return_ret_hash(online_pay)
						ret_hash['status']="success_notify"
						redirect_notify_url=OnlinePay.redirect_url_replace("post",online_pay.notification_url)
						logger.info("paypal post async url:#{redirect_notify_url}")
						unless online_pay.method_url_success?("post",redirect_notify_url,false,ret_hash)
							online_pay.set_status!("failure_notify_third","call notify_url wrong")
							online_pay.update_attributes!({})
						end

						cq.status="success"
						cq.last_callback_result="获取第三方支付系统验证交易成功"
					else
						cq.status="end"
						cq.last_callback_result="未缴费"

						cq.save
					end
				rescue=>e
					cq.status="failure"
					cq.last_callback_result=e.message
					cq.save
					Rails.logger.info("failure: #{e.message}")
				end
			end
			Rails.logger.info("#{cq.reference_id} process: #{cq.status},#{cq.last_callback_result}")
		end
	end

	def self.init_return_ret_hash(online_pay)
		{
			'trade_no'=>online_pay.trade_no,
			'status'=>"",
			'status_reason'=>"",
			'amount'=>online_pay.amount,
			'payway'=>online_pay.payway,
			'paytype'=>online_pay.paytype,
			'sign'=>Digest::MD5.hexdigest("#{online_pay.trade_no}#{Settings.authenticate.signkey}")
		}
	end
end
