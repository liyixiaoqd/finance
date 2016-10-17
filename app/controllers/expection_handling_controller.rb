class ExpectionHandlingController < ApplicationController
	def recall_notify
		if params[:online_pay_id].blank?
			flash[:notice]=DENY_PARAMS_MESSAGE
			redirect_to index_online_pay_path and return
		end

		op=OnlinePay.lock.find(params[:online_pay_id])
		if op.blank?
			flash[:notice]="无对应支付记录,请确认"
			redirect_to index_online_pay_path and return
		end

		begin
			op.with_lock do 
				ret_hash={
					'trade_no'=>op.trade_no,
					'status'=>"",
					'status_reason'=>"",
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

				redirect_notify_url=OnlinePay.redirect_url_replace("post",op.notification_url)
				response=op.method_url_response("post",redirect_notify_url,false,ret_hash)
				if response.code=="200" && JSON.parse(response.body)['status']=="success"
					op.set_status!("success_notify","")
					op.reconciliation_detail.update_attributes!({:online_pay_status=>op.status}) unless op.reconciliation_detail.blank? 
					op.save!()
					flash[:notice]="手动调用成功,请进行手动对账"
				else
					flash[:notice]="手动调用失败,后台任务自动重试"
				end
				# else
				# 	op.set_status!("failure_notify_third","recall info[#{response.code}:#{response.body}]")
				# end			
			end
		rescue => e
			logger.info("#{op.order_no} recall_notify 调用错误:#{e.message}")
			flash[:notice]="调用错误:#{e.message}"
		end

		redirect_to index_online_pay_path(payway: op.payway,paytype: op.paytype,order_no: op.order_no)
	end

	def manual_payment
		if params[:online_pay_id].blank?
			flash[:notice]=DENY_PARAMS_MESSAGE
			redirect_to index_online_pay_path and return
		end

		
		op=OnlinePay.lock.find(params[:online_pay_id])
		if op.blank?
			flash[:notice]="无对应支付记录,请确认"
			redirect_to index_online_pay_path and return
		end

		transactionid=""
		if op.payway=="alipay"
			transactionid=op.system+"_"+op.order_no
		elsif op.payway=="sofort"
			transactionid=op.trade_no
		elsif op.payway=="paypal"
			transactionid=params[:transactionid]
		else
			transactionid="EXPECTION_UNDEFINED"
		end
	
		if transactionid.blank? || transactionid=="null"
			if op.payway=="paypal"
				flash[:notice]="未输入支付交易号,请确认"
			else
				flash[:notice]="获取财务对应记录错误,请确认"
			end
			redirect_to index_online_pay_path(payway: op.payway,paytype: op.paytype,order_no: op.order_no) and return
		end

		if transactionid=="EXPECTION_UNDEFINED"
			flash[:notice]="不支持此类型进行手工支付"
			redirect_to index_online_pay_path(payway: op.payway,paytype: op.paytype,order_no: op.order_no) and return
		end

		rd_new_flag=false
		rd=ReconciliationDetail.find_by_transactionid(transactionid)
		if rd.blank?
			rd_new_flag=true
		else
			if rd.order_no.present? && rd.order_no!=op.order_no
				flash[:notice]="支付交易号已存在,属于[#{rd.order_no}]"
				redirect_to index_online_pay_path(payway: op.payway,paytype: op.paytype,order_no: op.order_no) and return	
			end
		end

		logger.info("reconciliation_detail insert or update: #{rd_new_flag}")

		begin
			op.with_lock do 
				desc="#{OnlinePay.current_time_format("%Y-%m-%d %H:%M:%S")} #{session[:admin]} 手工支付"

				op.status='success_notify'
				op.callback_status='TRADE_FINISHED'
				op.reconciliation_id=transactionid
				op.reason=desc
				ret_hash={
					'trade_no'=>op.trade_no,
					'status'=>op.status,
					'status_reason'=>op.callback_status,
					'amount'=>op.amount,
					'payway'=>op.payway,
					'paytype'=>op.paytype,
					'water_no'=>'',
					'sign'=>Digest::MD5.hexdigest("#{op.trade_no}#{Settings.authenticate.signkey}")		
				}

				if rd_new_flag
					op.set_reconciliation.save!()
				else
					rd.with_lock do
						rd.online_pay=op
						rd.online_pay_status=op.status 
						rd.country=op.country
						rd.send_country=op.send_country
						rd.order_no=op.order_no
						rd.system=op.system
						rd.reconciliation_flag="2"
						rd.reconciliation_describe=desc
						rd.online_pay_status=op.status

						rd.update_attributes!({})
					end
				end
				op.update_attributes!({})
				
				fw=FinanceWater.save_by_online_pay(op)
				ret_hash['water_no']=fw.id unless fw.blank?

				redirect_notify_url=OnlinePay.redirect_url_replace("post",op.notification_url)
				response=op.method_url_response("post",redirect_notify_url,false,ret_hash)
				if response.code=="200" && JSON.parse(response.body)['status']=="success"
					op.set_status!("success_notify","")
					op.reconciliation_detail.update_attributes!({:online_pay_status=>op.status}) unless op.reconciliation_detail.blank? 
					flash[:notice]="手动支付成功,请进行手动对账"
				else
					op.set_status!("failure_notify_third","recall info[#{response.code}:#{response.body}]")
					flash[:notice]="财务系统支付成功,调用异常,转入后台任务自动重试"
				end
				op.save!()
			end
		rescue => e
			flash[:notice]=e.message
		end

		redirect_to index_online_pay_path(payway: op.payway,paytype: op.paytype,order_no: op.order_no)
	end
end