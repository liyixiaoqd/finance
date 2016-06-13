class OnlinePayCallbackController < ApplicationController
	# include PayDetailable

	protect_from_forgery :except => [:alipay_oversea_notify,:alipay_transaction_notify]
	#Synchronous callback  --get 
	#alipay_oversea do nothing  only redirect to system_call_url
	def alipay_oversea_return
		render_text="failure"
		online_pay=OnlinePay.get_online_pay_instance("alipay","oversea",params,"",false,false)
		render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)

		ret_hash=init_return_ret_hash(online_pay)
		redirect_url=OnlinePay.redirect_url_replace("get",online_pay.success_url,ret_hash)
		logger.info("alipay_oversea_return:#{redirect_url}")
		# if(method_url_response_code("get",redirect_url,false)=="200")
		# 	render_text="success"
		# end

		# render text: "#{render_text}"
		redirect_to redirect_url
	end

	#Asynchronous callback --post
	def alipay_oversea_notify
		ActiveRecord::Base.transaction do   	#lock table
			logger.info(params[:out_trade_no])
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("alipay","oversea",params,"",false,true)
			render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.notification_url.blank?)

			#check is status has updated
			render :text=>'success' and return if online_pay.check_has_updated?(params[:trade_status])

			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
			#delete request params
			notify_params = params.except(*request.path_parameters.keys)
			#valid reques is right
			if(pay_detail.notify_verify?(notify_params,Settings.alipay_oversea.pid,Settings.alipay_oversea.secret))	
				begin
					ret_hash=init_notify_ret_hash(online_pay)
					rollback_callback_status=online_pay.callback_status
					online_pay.callback_status=params[:trade_status]
					online_pay.rate_amount=params[:total_fee]
					online_pay.set_status_by_callback!()
					online_pay.reconciliation_id=params[:out_trade_no]
					online_pay.thirdno=params[:trade_no]
					ret_hash['status']=online_pay.status
					ret_hash['status_reason']=online_pay.callback_status

					redirect_url=OnlinePay.redirect_url_replace("post",online_pay.notification_url)
					logger.info("alipay_oversea_notify:#{redirect_url}")
					online_pay.save!()
					if online_pay.is_success?() && online_pay.find_reconciliation().blank?
						online_pay.set_reconciliation.save!()
						#quaie spec proc!!!!!
						fw=FinanceWater.save_by_online_pay(online_pay)
						ret_hash['water_no']=fw.id unless fw.blank?
					end

					if !online_pay.method_url_success?("post",redirect_url,false,ret_hash)
						if online_pay.status=='success_notify'
							online_pay.set_status!("failure_notify_third","call notify_url wrong") 
							online_pay.update_attributes!({})
						end
					end

					render_text="success"
				rescue => e  	#rollback online_pay!!!
					#online_pay.set_status!("failure_notify",e.message)
					online_pay.update_attributes(:status=>"failure_notify",:reason=>e.message,:callback_status=>rollback_callback_status)
					logger.info("alipay_oversea_notify failure!! : #{e.message}")
				end
			end
			render text: "#{render_text}"
		end
	end	



	def alipay_transaction_return		
		render_text="failure"
		online_pay=OnlinePay.get_online_pay_instance("alipay","transaction",params,"",false,false)
		render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)


		if params['seller_email']==Settings.alipay_transaction.seller_email_direct
			pid,secret=Settings.alipay_transaction.pid_direct,Settings.alipay_transaction.secret_direct
		else
			pid,secret=Settings.alipay_transaction.pid,Settings.alipay_transaction.secret
		end

		pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
		#delete request params
		notify_params = params.except(*request.path_parameters.keys)
		#valid reques is right

		if(pay_detail.notify_verify?(notify_params,pid,secret))	
			ret_hash=init_return_ret_hash(online_pay)
			redirect_url=OnlinePay.redirect_url_replace("get",online_pay.success_url,ret_hash)
			logger.info("alipay_transaction_return:#{redirect_url}")
			# if(method_url_response_code("get",redirect_url,false)=="200")
			# 	render_text="success"
			# end
			redirect_to redirect_url and return
		end

		render text: "#{render_text}"
	end

	def alipay_transaction_notify
		ActiveRecord::Base.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("alipay","transaction",params)
			render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.notification_url.blank?)
			#check is status has updated
			render :text=>'success' and return if online_pay.check_has_updated?(params[:trade_status])

			if params['seller_email']==Settings.alipay_transaction.seller_email_direct
				pid,secret=Settings.alipay_transaction.pid_direct,Settings.alipay_transaction.secret_direct
			else
				pid,secret=Settings.alipay_transaction.pid,Settings.alipay_transaction.secret
			end

			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
			#delete request params
			notify_params = params.except(*request.path_parameters.keys)
			#valid reques is right
			if(pay_detail.notify_verify?(notify_params,pid,secret))	
				begin
					ret_hash=init_notify_ret_hash(online_pay)
					rollback_callback_status=online_pay.callback_status
					online_pay.callback_status=params[:trade_status]
					online_pay.set_status_by_callback!()
					online_pay.reconciliation_id=params[:trade_no]
					online_pay.thirdno=params[:trade_no]
					ret_hash['status']=online_pay.status
					ret_hash['status_reason']=online_pay.callback_status
					ret_hash['buyer_email'] = params[:buyer_email]
					ret_hash['buyer_id'] = params[:buyer_id]

					redirect_url=OnlinePay.redirect_url_replace("post",online_pay.notification_url)
					logger.info("alipay_transaction_notify:#{redirect_url}")
				
					#auto send order
					if(online_pay.callback_status=="WAIT_SELLER_SEND_GOODS")
						message=pay_detail.auto_send_good_success(online_pay.reconciliation_id)
						unless message=="success"
							logger.warn("Auto Send Good failure!!:#{message}")
							raise message
						end
					end

					online_pay.save!()
					if online_pay.is_success?() && online_pay.find_reconciliation().blank?
						reconciliation_flag=false
						reconciliation_flag=true if online_pay.callback_status=="WAIT_BUYER_CONFIRM_GOODS"
						if rollback_callback_status!="WAIT_BUYER_CONFIRM_GOODS"
							reconciliation_flag=true if online_pay.callback_status=="TRADE_FINISHED" ||online_pay.callback_status=="TRADE_SUCCESS"
						end
						
						if reconciliation_flag==true
							logger.info("#{online_pay.order_no},#{online_pay.callback_status} alipay transaction insert into reconciliation!!")
							online_pay.set_reconciliation.save!()
							fw=FinanceWater.save_by_online_pay(online_pay)
							ret_hash['water_no']=fw.id unless fw.blank?
						else
							logger.info("#{online_pay.order_no},#{online_pay.callback_status} alipay transaction do not insert into reconciliation!! #{online_pay.callback_status} and #{rollback_callback_status}")
						end
					end
					# response_code=online_pay.method_url_response_code("post",redirect_url,false,ret_hash)
					# unless response_code=="200"
					# 	raise "call #{redirect_url} failure : #{response_code}"
					# end
					if !online_pay.method_url_success?("post",redirect_url,false,ret_hash)
						if online_pay.status=='success_notify'
							online_pay.set_status!("failure_notify_third","call notify_url wrong") 
							online_pay.update_attributes!({})
						end
					end
					render_text="success"	
				rescue => e
					#online_pay.set_status!("failure_notify",e.message)
					online_pay.update_attributes(:status=>"failure_notify",:reason=>e.message,:callback_status=>rollback_callback_status)
					logger.info("alipay_transaction_notify failure!! : #{e.message}")
				end
			end
			render text: "#{render_text}"
		end
	end



	def paypal_return
		render_text="failure"
		#第一次锁订单数据 更新状态为正在处理
		#1. 防止paypal调用多次同步接口,导致数据覆盖
		#2. 防止订单再次调用支付接口,形成重复数据
		online_pay=''
		cq=''
		ActiveRecord::Base.transaction do
			online_pay=OnlinePay.get_online_pay_instance("paypal","",params,"",false,true)
			render text: "#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)
			cq=CallQueue.online_pay_is_succ_record(online_pay.id)
			# check is status has updated!
			if online_pay.status=="success_notify" || online_pay.status=="failure_notify_third" || online_pay.status=="intermediate_notify"
				redirect_url=OnlinePay.redirect_url_replace("get",online_pay.abort_url,{})
				logger.info("paypal return has call:#{online_pay.status} and redirect_to #{redirect_url}")
				redirect_to redirect_url and return
			end
			
			#online_pay.with_lock do
			online_pay.update_attributes(status: "intermediate_notify")
			#end
		end

		#第二次保持事务
		ActiveRecord::Base.transaction do
			begin
				#online_pay.callback_status,rollback_callback_status=rollback_callback_status,online_pay.callback_status

				pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
				ret_hash=init_return_ret_hash(online_pay)
				
				pay_id_details=pay_detail.get_pay_details(online_pay.trade_no)
				if pay_id_details.blank?
					logger.info("PAYPAL get_pay_details FAILURE")
					raise "PAYPAL get_pay_details FAILURE"
				else	
					online_pay.credit_pay_id = pay_id_details.payer_id
					online_pay.credit_first_name = pay_id_details.params["first_name"]
					online_pay.credit_last_name = pay_id_details.params["last_name"]
					online_pay.credit_email = pay_id_details.params["payer"]
				end

				flag,message,online_pay.reconciliation_id,online_pay.callback_status=pay_detail.process_purchase(online_pay)

				if flag==false
					raise message
					#CallQuene中进行调用
					
					#超时 调用对账程序获取状态
					# if message=="execution expired"
					# 	logger.info("[MONITOR]: TIME_OUT and RETRY GET #{online_pay.order_no}")
					# 	sleep 5
					# 	rp=ReconciliationPaypal.new("TransactionSearch",online_pay.country)
					# 	flag,message,online_pay.reconciliation_id,online_pay.callback_status=rp.has_pay_order(online_pay.credit_email,online_pay.amount)
					# 	if flag==false
					# 		logger.info("RETRY GET failure:#{message}")
					# 		raise message
					# 	else
					# 		logger.info("RETRY GET SUCCESS")
					# 	end
					# else
					# 	raise message
					# end
				end

				if  online_pay.callback_status.blank? || (!Settings.paypal.success_callback_status.include? online_pay.callback_status)
					logger.info("MONITOR : PAYPAL CALLBACK_STATUS:"+online_pay.callback_status)
					raise "PaymentStatus failure: #{online_pay.callback_status}"
				end

				online_pay.set_status!("success_notify","")
				online_pay.save!()
				if online_pay.is_success?() && online_pay.find_reconciliation().blank?
					online_pay.set_reconciliation.save!()
					cq.online_pay_is_succ_set() unless cq.blank?
				end

				ret_hash['status']="success_notify"
				redirect_notify_url=OnlinePay.redirect_url_replace("post",online_pay.notification_url)
				logger.info("paypal post async url:#{redirect_notify_url}")
				unless online_pay.method_url_success?("post",redirect_notify_url,false,ret_hash)
					online_pay.set_status!("failure_notify_third","call notify_url wrong")
					online_pay.update_attributes!({})
				end
			rescue => e
				ret_hash['status']="failure"
				ret_hash['status_reason']=e.message
				unless (online_pay.blank?)
					online_pay.update_attributes(:status=>"failure_credit",:reason=>e.message)
				end
				logger.info("paypal return rescue:#{e.message}")
			end
			# ret_hash['credit_pay_id'] = online_pay.credit_pay_id
			# ret_hash['credit_first'] = online_pay.credit_first_name
			# ret_hash['credit_second'] = online_pay.credit_last_name

			# unless online_pay.save()
			# 	logger.warn("paypal_return:save failure!")
			# end
			logger.info(ret_hash)
			#add post notify_url

			logger.info("paypal get sync url:#{online_pay.success_url}")
			redirect_to OnlinePay.redirect_url_replace("get",online_pay.success_url,ret_hash)
		end
	end
	
	def paypal_abort
		ActiveRecord::Base.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("paypal","",params,"",false,true)
			render text: "#{render_text}" and return if (online_pay.blank? || online_pay.abort_url.blank?)

			redirect_url=OnlinePay.redirect_url_replace("get",online_pay.abort_url,{})
			logger.info("paypal_abort:#{redirect_url}")
			# if(method_url_response_code("get",redirect_url,false)=="200")
			# 	render_text="success"
			# end
			# check is status has updated!
			if online_pay.status=="success_notify" || online_pay.status=="failure_notify_third"
				logger.warn("paypal_abort:#{online_pay.order_no} has success!! can not abort!")
			else
				online_pay.set_status!("cancel_notify","abort")
				unless online_pay.save()
					logger.warn("paypal_abort:save abort failure!")
				end
			end
			

			redirect_to redirect_url
		end
	end
	


	def sofort_return
		###sofort return no params!   no use this interface!
		#sofort return url: /system/order_no
		render_text="failure"
		#online_pay=OnlinePay.get_online_pay_instance("sofort","",params,"",false,false)
		online_pay=OnlinePay.find_by_system_and_payway_and_order_no(params['system'],"sofort",params['order_no'])
		render text: "#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)

		ret_hash=init_return_ret_hash(online_pay)
		redirect_url=OnlinePay.redirect_url_replace("get",online_pay.success_url,ret_hash)
		logger.info("sofort_return:#{redirect_url}")
		# if(method_url_response_code("get",redirect_url,false)=="200")
		# 	render_text="success"
		# end

		# render text: "#{render_text}"
		redirect_to redirect_url
	end
	
	def sofort_notify
		#sofort使用XML进行回调,已配置rails自行进行解析
		if params.size==2
			#
			#<?xml version="1.0" encoding="UTF-8" ?>
			# <status_notification>
			# 	<transaction>84221-175012-559CDBE7-8C71</transaction>
			# 	<time>2015-07-08T10:15:06+02:00</time>
			# </status_notification>
			#
			params.merge! SofortDetail.getStatusFromXml(request.body.read)
			logger.info("xml proc self!!!  sofort_notify:#{params}")
		end

		ActiveRecord::Base.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("sofort","",params,"",false,true)
			render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.notification_url.blank?)
			cq=CallQueue.online_pay_is_succ_record(online_pay.id)

			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
			
			ret_hash=init_notify_ret_hash(online_pay)
			rollback_callback_status,online_pay.reason=pay_detail.identify_transaction(online_pay.trade_no,online_pay.country)
			#check is status has updated
			logger.warn("sofort_notify:identify_transaction failure") if rollback_callback_status.blank?
			render :text=>'success' and return if online_pay.check_has_updated?(rollback_callback_status)

			online_pay.callback_status,rollback_callback_status=rollback_callback_status,online_pay.callback_status
			online_pay.set_status_by_callback!()

			online_pay.reconciliation_id=online_pay.trade_no

			ret_hash['status']=online_pay.status
			ret_hash['status_reason']=online_pay.callback_status

			redirect_url=OnlinePay.redirect_url_replace("post",online_pay.notification_url)
			logger.info("sofort_notify:#{redirect_url}")

			begin
				online_pay.save!()
				if online_pay.is_success?() && online_pay.find_reconciliation().blank?
					online_pay.set_reconciliation.save!()
					cq.online_pay_is_succ_set() unless cq.blank?
				end
				# response_code=online_pay.method_url_response_code("post",redirect_url,false,ret_hash)
				# unless response_code=="200"
				# 	raise "call #{redirect_url} failure : #{response_code}"
				# end
				if !online_pay.method_url_success?("post",redirect_url,false,ret_hash)
					if online_pay.status=='success_notify'
						online_pay.set_status!("failure_notify_third","call notify_url wrong")
						online_pay.update_attributes!({})
					end
				end

				render_text="success"
			rescue => e
				online_pay.update_attributes(:status=>"failure_notify",:reason=>e.message,:callback_status=>rollback_callback_status)
				logger.info("sofort_notify failure!! : #{e.message},[#{params}]")
			end

			render text: "#{render_text}"
		end
	end
	
	def sofort_abort
		###sofort return no params!   no use this interface!
		#sofort return url: /system/order_no
		ActiveRecord::Base.transaction do
			render_text="failure"

			online_pay=OnlinePay.lock.find_by_system_and_payway_and_order_no(params['system'],"sofort",params['order_no'])
			#online_pay=OnlinePay.get_online_pay_instance("sofort","",params,"",false,true)
			render text: "#{render_text}" and return if (online_pay.blank? || online_pay.abort_url.blank?)

			redirect_url=OnlinePay.redirect_url_replace("get",online_pay.abort_url,{})
			logger.info("sofort_abort:#{redirect_url}")
			# if(method_url_response_code("get",redirect_url,false)=="200")
			# 	render_text="success"
			# end

			# render text: "#{render_text}"		
			online_pay.set_status!("cancel_notify","abort or timeout")
			rollback_callback_status=online_pay.status		
			#check is status has updated
			if online_pay.check_has_updated?(rollback_callback_status)
				logger.warn("sofort_abort:#{online_pay.order_no} has success!! can not abort!")
			else
				online_pay.callback_status,rollback_callback_status=rollback_callback_status,online_pay.callback_status
				unless online_pay.save()
					logger.warn("sofort_abort:save abort or timeout failure!")
				end
			end

			redirect_to redirect_url
		end
	end

	private 
		def init_return_ret_hash(online_pay)
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

		def init_notify_ret_hash(online_pay)
			{
				'trade_no'=>online_pay.trade_no,
				'status'=>"",
				'status_reason'=>"",
				'amount'=>online_pay.amount,
				'payway'=>online_pay.payway,
				'paytype'=>online_pay.paytype,
				'water_no'=>'',
				'sign'=>Digest::MD5.hexdigest("#{online_pay.trade_no}#{Settings.authenticate.signkey}")		
			}
		end
end