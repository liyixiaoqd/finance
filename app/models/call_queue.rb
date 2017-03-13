require 'concerns/net_http_auth.rb'

class CallQueue < ActiveRecord::Base
	include PayDetailable
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

	#oceanpayment_push_task - 1
	def self.oceanpayment_push_task_save!(reconciliation_detail_id,oceanpayment_payment_id)
		if reconciliation_detail_id.blank? or oceanpayment_payment_id.blank?
			raise "CallQueue.save_oceanpayment_push_task excepiton: params null"
		end

		if CallQueue.find_by_callback_interface_and_reference_id("oceanpayment_push",reconciliation_detail_id).blank?	
			cq=CallQueue.new
			cq.callback_interface="oceanpayment_push"
			cq.reference_id=reconciliation_detail_id
			cq.status="init"
			cq.try_amount=10
			cq.tried_amount=0
			cq.run_batch=oceanpayment_payment_id
			cq.start_call_time=Time.now.utc.to_s[0,19]	#5分钟后才允许调用 UTC

			unless cq.save
				raise "CallQueue.save_oceanpayment_push_task excepiton: #{cq.errors.full_messages}"
			end
		end
	end


	#oceanpayment_push_task - 2
	def self.oceanpayment_push_task_get_info()
		p "CallQueue.oceanpayment_push_task_get_info start [#{Time.now}]"
		max_call_num=30
		count=0
		cq_array=[]
		CallQueue.where(callback_interface: "oceanpayment_push",status: ["init","get_track_info"]).each do |cq|
			count+=1
			cq_array<<cq
			if count>=max_call_num
				oceanpayment_push_task_get_info_proc(cq_array)
				count=0
				cq_array=[]
			end
		end

		if count>0
			oceanpayment_push_task_get_info_proc(cq_array)
			count=0
			cq_array=[]
		end

		p "CallQueue.oceanpayment_push_task_get_info end [#{Time.now}]"
	end

	def self.oceanpayment_push_task_get_info_proc(cq_array)
		begin
			post_params={"order_numbers"=>[]}
			cq_array.each do |cq|
				rd=ReconciliationDetail.find_by(id: cq.reference_id)
				if rd.blank?
					p "id[#{cq.reference_id}] is null?????"
					next
				end

				if rd.system=="mypost4u"
					post_params["order_numbers"]<<{
						"order_no"=>rd.order_no,
						"trade_no"=>rd.online_pay.trade_no
					}
				end
			end
			
			if post_params["order_numbers"].length==0
				p "no info need call"
				return
			end

			p "CallQueue.oceanpayment_push_task_get_info_proc post_params : [#{post_params}]"
			response=method_url_call_http_auth("post",Settings.mypost4u.get_track_info_url,Settings.authenticate.username,Settings.authenticate.passwd,post_params)
			if response.code!="200" 
				raise "call [#{Settings.mypost4u.get_track_info_url}] failure: [#{response.code}]"
			end

			ret_hash=JSON.parse response.body
			ret_hash['logistics_informations'].each do |track_info|
				p "return track_info  [#{track_info}]"
				rd=OnlinePay.find_by(trade_no: track_info['trade_no']).reconciliation_detail
				if rd.blank?
					p "no ReconciliationDetail found?? [#{track_info['trade_no']}]"
					next
				end

				cq_array.each do |cq|
					if cq.reference_id.to_i == rd.id.to_i
						cq.tried_amount+=1

						if track_info["is_complete"]=="S"
							p "[#{track_info['trade_no']}] no need to call"
							cq.status="finished_no_push"
						elsif track_info["is_complete"]=="Y"
							cq.status="need_push"
							cq.tried_amount=0
							cq.try_amount=3

							opti=OnlinePayTrackInfo.find_by(order_no: rd.order_no)
							if opti.blank?
								opti=OnlinePayTrackInfo.new(order_no: rd.order_no)
							end
							opti.ishpmt_nums=track_info["ishpmt_num"]
							opti.tracking_urls=track_info["tracking_url"]
							opti.online_pay_id=rd.online_pay_id

							opti.save!
						else
							p "[#{track_info['trade_no']}] unfinished call next time"

							if cq.tried_amount>=cq.try_amount
								cq.status="limit_get_track_info"
							else
								cq.status="get_track_info"
							end
						end

						cq.save!
						cq_array.delete(cq)
						break
					end
				end
			end
		rescue=>e
			p e.message
		end
	end


	#oceanpayment_push_task - 3
	def self.oceanpayment_push_task_push()
		p "CallQueue.oceanpayment_push_task_push start [#{Time.now}]"
		CallQueue.where(callback_interface: "oceanpayment_push",status: ["need_push","pushing"]).each do |cq|
			begin
				cq.tried_amount+=1
				push_flag=ReconciliationOceanpayment.push_track_info(ReconciliationDetail.find_by(id: cq.reference_id).online_pay)
				if push_flag==true
					cq.status="finished_pushed"
				else
					if cq.tried_amount>=cq.try_amount
						cq.status="limit_pushing"
					else
						cq.status="pushing"
					end
				end
				cq.save!
				p "CallQueue.oceanpayment_push_task_push [#{cq.reference_id}]  push result , [#{cq.status}]"
			rescue=>e
				p "CallQueue.oceanpayment_push_task_push rescue: #{e.message}"
			end
		end

		p "CallQueue.oceanpayment_push_task_push end [#{Time.now}]"
	end
end
