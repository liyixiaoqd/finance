class OnlinePayCallbackController < ApplicationController
	include PayDetailable

	protect_from_forgery :except => [:alipay_oversea_notify,:alipay_transaction_notify]
	#Synchronous callback  --get 
	#alipay_oversea do nothing  only redirect to system_call_url
	def alipay_oversea_return
		render_text="failure"
		online_pay=OnlinePay.get_online_pay_instance("alipay","oversea",params,"",false,false)
		render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)

		ret_hash=init_return_ret_hash(online_pay)
		redirect_url=redirect_url_replace("get",online_pay.success_url,ret_hash)
		logger.info("alipay_oversea_return:#{redirect_url}")
		# if(method_url_response_code("get",redirect_url,false)=="200")
		# 	render_text="success"
		# end

		# render text: "#{render_text}"
		redirect_to redirect_url
	end

	#Asynchronous callback --post
	def alipay_oversea_notify
		OnlinePay.transaction do   	#lock table
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
					online_pay.reconciliation_id=online_pay.trade_no
					ret_hash['status']=online_pay.status
					ret_hash['status_reason']=online_pay.callback_status

					redirect_url=redirect_url_replace("post",online_pay.notification_url)
					logger.info("alipay_oversea_notify:#{redirect_url}")
				
					online_pay.save!()
					response_code=method_url_response_code("post",redirect_url,false,ret_hash)
					unless response_code=="200"
						raise "call #{redirect_url} failure : #{response_code}"
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

		pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
		#delete request params
		notify_params = params.except(*request.path_parameters.keys)
		#valid reques is right

		if(pay_detail.notify_verify?(notify_params,Settings.alipay_transaction.pid,Settings.alipay_transaction.secret))	
			ret_hash=init_return_ret_hash(online_pay)
			redirect_url=redirect_url_replace("get",online_pay.success_url,ret_hash)
			logger.info("alipay_transaction_return:#{redirect_url}")
			# if(method_url_response_code("get",redirect_url,false)=="200")
			# 	render_text="success"
			# end
			redirect_to redirect_url and return
		end

		render text: "#{render_text}"
	end

	def alipay_transaction_notify
		OnlinePay.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("alipay","transaction",params)
			render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.notification_url.blank?)
			#check is status has updated
			render :text=>'success' and return if online_pay.check_has_updated?(params[:trade_status])

			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
			#delete request params
			notify_params = params.except(*request.path_parameters.keys)
			#valid reques is right
			if(pay_detail.notify_verify?(notify_params,Settings.alipay_transaction.pid,Settings.alipay_transaction.secret))	
				begin
					ret_hash=init_notify_ret_hash(online_pay)
					rollback_callback_status=online_pay.callback_status
					online_pay.callback_status=params[:trade_status]
					online_pay.set_status_by_callback!()
					online_pay.reconciliation_id=params[:trade_no]
					ret_hash['status']=online_pay.status
					ret_hash['status_reason']=online_pay.callback_status
					ret_hash['buyer_email'] = params[:buyer_email]
					ret_hash['buyer_id'] = params[:buyer_id]

					redirect_url=redirect_url_replace("post",online_pay.notification_url)
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
					response_code=method_url_response_code("post",redirect_url,false,ret_hash)
					unless response_code=="200"
						raise "call #{redirect_url} failure : #{response_code}"
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
		OnlinePay.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("paypal","",params,"",false,true)
			render text: "#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)

			online_pay.set_status!("submit_credit","")
			rollback_callback_status=online_pay.status
			#check is status has updated
			render :text=>'success' and return if online_pay.check_has_updated?(rollback_callback_status)

			online_pay.callback_status,rollback_callback_status=rollback_callback_status,online_pay.callback_status

			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
			ret_hash=init_return_ret_hash(online_pay)
			
			pay_detail.get_pay_details!(online_pay)

			ret_hash['credit_pay_id'] = online_pay.credit_pay_id
			ret_hash['credit_first'] = online_pay.credit_first_name
			ret_hash['credit_second'] = online_pay.credit_last_name

			unless online_pay.save()
				logger.warn("paypal_return:save failure!")
			end

			redirect_to redirect_url_replace("get",online_pay.success_url,ret_hash)
		end
	end
	
	def paypal_abort
		OnlinePay.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("paypal","",params,"",false,true)
			render text: "#{render_text}" and return if (online_pay.blank? || online_pay.abort_url.blank?)

			# render text: "#{render_text}"		
			online_pay.set_status!("cancel_notify","abort")
			rollback_callback_status=online_pay.status	
			#check is status has updated
			render :text=>'success' and return if online_pay.check_has_updated?(rollback_callback_status)
			
			online_pay.callback_status,rollback_callback_status=rollback_callback_status,online_pay.callback_status

			redirect_url=redirect_url_replace("get",online_pay.abort_url,{})
			logger.info("paypal_abort:#{redirect_url}")
			# if(method_url_response_code("get",redirect_url,false)=="200")
			# 	render_text="success"
			# end



			unless online_pay.save()
				logger.warn("paypal_abort:save abort failure!")
			end

			redirect_to redirect_url
		end
	end
	


	def sofort_return
		render_text="failure"
		online_pay=OnlinePay.get_online_pay_instance("sofort","",params,"",false,false)
		render text: "#{render_text}" and return if (online_pay.blank? || online_pay.success_url.blank?)

		ret_hash=init_return_ret_hash(online_pay)
		redirect_url=redirect_url_replace("get",online_pay.success_url,ret_hash)
		logger.info("sofort_return:#{redirect_url}")
		# if(method_url_response_code("get",redirect_url,false)=="200")
		# 	render_text="success"
		# end

		# render text: "#{render_text}"
		redirect_to redirect_url
	end
	
	def sofort_notify
		OnlinePay.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("sofort","",params,"",false,true)
			render :text=>"#{render_text}" and return if (online_pay.blank? || online_pay.notification_url.blank?)

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

			redirect_url=redirect_url_replace("post",online_pay.notification_url)
			logger.info("sofort_notify:#{redirect_url}")

			begin
				online_pay.save!()
				response_code=method_url_response_code("post",redirect_url,false,ret_hash)
				unless response_code=="200"
					raise "call #{redirect_url} failure : #{response_code}"
				end

				render_text="success"
			rescue => e
				online_pay.update_attributes(:status=>"failure_notify",:reason=>e.message,:callback_status=>rollback_callback_status)
				logger.info("sofort_notify failure!! : #{e.message}")
			end

			render text: "#{render_text}"
		end
	end
	
	def sofort_abort
		OnlinePay.transaction do
			render_text="failure"
			online_pay=OnlinePay.get_online_pay_instance("sofort","",params,"",false,true)
			render text: "#{render_text}" and return if (online_pay.blank? || online_pay.abort_url.blank?)

			# render text: "#{render_text}"		
			online_pay.set_status!("cancel_notify","abort or timeout")
			rollback_callback_status=online_pay.status		
			#check is status has updated
			render :text=>'success' and return if online_pay.check_has_updated?(rollback_callback_status)

			online_pay.callback_status,rollback_callback_status=rollback_callback_status,online_pay.callback_status

			redirect_url=redirect_url_replace("get",online_pay.abort_url,{})
			logger.info("sofort_abort:#{redirect_url}")
			# if(method_url_response_code("get",redirect_url,false)=="200")
			# 	render_text="success"
			# end

			unless online_pay.save()
				logger.warn("sofort_abort:save abort or timeout failure!")
			end

			redirect_to redirect_url
		end
	end

	private 
		def redirect_url_replace(method,redirect_url,ret_hash={})
			new_redirect_url=""
			if(method=="get")
				params_url=ret_hash.map do |key,value|
					"#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
				end.join("&")
				new_redirect_url=redirect_url+"?"+params_url
			else
				new_redirect_url=redirect_url
			end

			new_redirect_url
		end

		def init_return_ret_hash(online_pay)
			{
				'trade_no'=>"#{online_pay.trade_no}",
				'is_credit'=>"#{online_pay.is_credit}",
				'credit_pay_id'=>'',
				'credit_first'=>'',
				'credit_second'=>''
			}
		end

		def init_notify_ret_hash(online_pay)
			{
				'trade_no'=>online_pay.trade_no,
				'status'=>'',
				'status_reason'=>'',
				'amount'=>online_pay.amount,
				'test_mode'=>false,
				'buyer_email'=>'',
				'buyer_id'=>''			
			}
		end
end