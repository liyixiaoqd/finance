class TransactionReconciliationController < ApplicationController
	# before_action :authenticate_admin!
	include OnlinePayHelper
	include TransactionReconciliationHelper
	include Timeutilsable
	include Enumsable

	CONDITION_PARAMS=%w{payway paytype reconciliation_flag start_time end_time transactionid online_pay_id confirm_flag send_country system order_no}
	# def index
	# 	@reconciliation_details=ReconciliationDetail.includes(:online_pay).all.page(params[:page])

	# 	respond_to do |format|
	# 		format.js { }
	# 		format.html { render :index }
	# 	end
	# end

	def index
		#logger.info(sql)
		# unless (params['order_no'].blank?)
		# 	ops=OnlinePay.where("order_no=?",params['order_no'])
		# 	unless ops.blank?
		# 		params['online_pay_id']=[]
		# 		ops.each do |op|
		# 			params['online_pay_id']<<op.id
		# 		end
		# 	else
		# 		return
		# 	end
		# end
		
		sql=sql_from_condition_filter(params)
		@reconciliation_details=ReconciliationDetail.includes(:online_pay).where(sql,params).page(params[:page])
		
		# @reconciliation_details=Kaminari.paginate_array(@reconciliation_details).page(params[:page]).per(ReconciliationDetail::PAGE_PER)
		respond_to do |format|
			format.html { render :index }
			format.js
		end
	end

	def export
		# unless (params['order_no'].blank?)
		# 	ops=OnlinePay.where("order_no=?",params['order_no'])
		# 	unless ops.blank?
		# 		params['online_pay_id']=[]
		# 		ops.each do |op|
		# 			params['online_pay_id']<<op.id
		# 		end
		# 	else
		# 		flash[:notice]="无可导出记录"
		# 		redirect_to transaction_reconciliation_index_path and return
		# 	end
		# end
		
		sql=sql_from_condition_filter(params)

		if sql.blank?
			flash[:notice]="无可导出记录"
			redirect_to transaction_reconciliation_index_path and return
		end

		reconciliation_details=ReconciliationDetail.includes(:online_pay).where(sql,params)

		csv_string = CSV.generate do |csv|
			csv << ["导出工号", session[:admin],"导出时间", OnlinePay.current_time_format("%Y-%m-%d %H:%M:%S")]
			csv << []
			csv << ["支付类型", "子类型","交易号", "订单号/补款号", "对账状态","金额","货币","交易完成时间","交易状态","交易发起日期","交易来源系统","包裹发送国家","用户名","注册E-Mail"]
			reconciliation_details.each do |rd|
				out_arr=[rd.payway,rd.paytype,rd.transactionid,rd.order_no,
				                reconciliation_flag_mapping(rd.reconciliation_flag),
				                rd.amt,rd.currencycode,rd.timestamp]
				unless rd.online_pay.blank?         
					out_arr += [status_mapping(rd.online_pay.status),rd.online_pay.created_at,system_mapping(rd.system),
						      rd.online_pay.send_country,rd.online_pay.user.username,rd.online_pay.user.email]
				end
				csv << out_arr
			end
		end

		send_data csv_string,:type => 'text/csv ',:disposition => "filename=财务对账明细_#{OnlinePay.current_time_format("%Y%m%d%H%M%S")}.csv"
	end

	def report
		payway=params['payway']
		paytype=params['paytype']
		send_country=params['send_country']
		start_time=params['start_time']
		end_time=params['end_time']

		if start_time.blank? || end_time.blank?
			@finance_summary=FinanceSummary.new(OnlinePay.current_time_format("%Y-%m-%d",-1),OnlinePay.current_time_format("%Y-%m-%d",0))
		else
			@finance_summary=FinanceSummary.new(start_time,end_time,1)
			condition=""
			condition+="and payway='#{payway}'" unless payway.blank?
			condition+=" and paytype='#{paytype}'" unless paytype.blank?
			condition+=" and send_country='#{send_country}'" unless send_country.blank?
			@finance_summary.setAmountAndNum!(condition)
			logger.info(@finance_summary.output)
		end

		respond_to do |format|
			format.html { render :report }
			format.js
		end
	end

	def modify
		begin 
			ActiveRecord::Base.transaction do
				reconciliation_detail=ReconciliationDetail.lock.find(params[:transactionid])
				if reconciliation_detail.reconciliation_flag!=params[:flag]
					flash[:notice]="#{params[:transactionid]}对账状态已发生变更,与提交时不同,请重新确认"
					redirect_to transaction_reconciliation_index_path(payway: reconciliation_detail.payway,paytype: reconciliation_detail.paytype,transactionid: reconciliation_detail.transactionid) and return
				end
				if (reconciliation_detail.reconciliation_flag==ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC'])
					#已财务确认的不可撤销
					if reconciliation_detail.confirm_flag==ReconciliationDetail::CONFIRM_FLAG['SUCC']
						raise "财务已确认,不可撤销"
					end
					reconciliation_detail.reconciliation_flag=ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['FAIL']

					# 屏蔽增加客户积分功能,此为业务系统逻辑
					# if reconciliation_detail.online_pay.blank? || reconciliation_detail.online_pay.user.blank?
					# 	raise "此记录无对应用户信息"
					# end

					# user=reconciliation_detail.online_pay.user
					# user.with_lock do
					# 	reason="财务#{session[:admin]}手工撤销对账记录:#{reconciliation_detail.transactionid}"
					# 	user.create_finance("e_cash","",reconciliation_detail.amt,"Add") && user.update_attributes({:e_cash=>reconciliation_detail.amt+user.e_cash})
					# 	if user.errors.any?
					# 		errmsg="客户账户处理出错:"
					# 		user.errors.full_messages.each do |msg|
					# 			errmsg+=msg+";"
					# 		end
					# 		raise errmsg
					# 	end
					# end
				else
					if params['transaction_date'].blank? ||  isNotTime?(params['transaction_date'])
						logger.info("!!!!!!!!!!!!#{params['transaction_date']}")
						raise "请输入对账确认日期!!"
					else
						reconciliation_detail.transaction_date=params['transaction_date']
					end
					reconciliation_detail.reconciliation_flag=ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC']
				end
				reconciliation_detail.reconciliation_describe="#{OnlinePay.current_time_format("%Y-%m-%d %H:%M:%S")} #{session[:admin]} 手工修改状态:#{reconciliation_detail.reconciliation_flag}"
				reconciliation_detail.update_attributes({})
				flash[:notice]="#{reconciliation_detail.transactionid}操作成功"
				redirect_to transaction_reconciliation_index_path(payway: reconciliation_detail.payway,paytype: reconciliation_detail.paytype,transactionid: reconciliation_detail.transactionid) and return
			end
		rescue => e 
			flash[:notice]="更新状态出错:#{e.message}"
			redirect_to transaction_reconciliation_index_path() and return
		end
		
	end

	def confirm_search
		if params['start_time'].blank?
			params['start_time']=OnlinePay.current_time_format("%Y-%m-%d",-1)
			
		end

		sql="reconciliation_flag=#{ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC']} and confirm_flag=#{ReconciliationDetail::CONFIRM_FLAG['INIT']} "
		sql+="and transaction_date=:start_time " unless params['start_time'].blank?
		sql+="and system=:system " unless params['system'].blank?
		sql+="and send_country=:send_country" unless params['send_country'].blank?

		@confirm_num,@confirm_amount,@max_updated_at=ReconciliationDetail.get_confirm_summary(sql,params)

		@system=params['system']
		@send_country=params['send_country']
		@transaction_date=params['start_time']
	end

	def confirm
		begin
			if params['passwd'].blank?
				flash[:notice]="请输入密码后再进行确认"
				redirect_to transaction_reconciliation_confirm_search_path and return
			end

			if AdminManage.valid_admin({'admin_name'=>session['admin'],'admin_passwd_encryption'=>params['passwd']}).blank?
				flash[:notice]="密码输入错误,请重新确认"
				redirect_to transaction_reconciliation_confirm_search_path and return
			end

			if params['confirm_num'].blank? || params['confirm_num'].to_i==0
				flash[:notice]="无可确认数据! 提交未确认比数: #{params['confirm_num']}"
				redirect_to transaction_reconciliation_confirm_search_path and return
			end
			# if params['end_time'].blank? 
			# 	flash[:notice]="请输入确认发票日期"
			# 	redirect_to transaction_reconciliation_confirm_search_path and return
			# end

			all_amount=0.0
			confirm_date=OnlinePay.current_time_format("%Y-%m-%d")

			sql="reconciliation_flag=#{ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['SUCC']} and confirm_flag=#{ReconciliationDetail::CONFIRM_FLAG['INIT']} "
			sql+="and updated_at<=:max_updated_at "  
			sql+="and transaction_date=:start_time " unless params['start_time'].blank?
			sql+="and system=:system " unless params['system'].blank?
			sql+="and send_country=:send_country" unless params['send_country'].blank?

			ReconciliationDetail.transaction do
				reconciliation_details=ReconciliationDetail.lock.where(sql,params)

				if reconciliation_details.size != params['confirm_num'].to_i
					raise "数据已变更,请重新确认! 比数 #{params['confirm_num']} => #{reconciliation_details.size}"
				end

				reconciliation_details.each do |rd|
					all_amount+=rd.amt
				end

				if all_amount != params['confirm_amount'].to_f
					raise "数据已变更,请重新确认! 金额 #{params['confirm_amount']} => #{all_amount}"
				end

				reconciliation_details.each do |rd|
					rd.confirm_flag=ReconciliationDetail::CONFIRM_FLAG['SUCC']
					rd.confirm_date=confirm_date
					if rd.reconciliation_describe.blank?
						rd.reconciliation_describe="#{OnlinePay.current_time_format("%Y-%m-%d %H:%M:%S")} #{session[:admin]} 发票确认"
					else
						rd.reconciliation_describe+=";#{OnlinePay.current_time_format("%Y-%m-%d %H:%M:%S")} #{session[:admin]} 发票确认"
					end
					rd.update_attributes({})
				end
			end

			flash[:notice]="#{params['start_time']}_#{params['system']}_#{params['send_country']} 确认发票成功!! 确认比数:#{params['confirm_num']},确认金额:#{params['confirm_amount']}"
		rescue => e
			flash[:notice]=e.message
		end

		redirect_to transaction_reconciliation_confirm_search_path
	end

	private 
		def sql_from_condition_filter(params)
			sql="reconciliation_flag<>#{ReconciliationDetail::RECONCILIATIONDETAIL_FLAG['NON_SYSTEM']}"

			params.each do |k,v|
				next if v.blank? 
				next unless CONDITION_PARAMS.include?(k)
				
				if( k=="start_time")
					t_sql="timestamp>=:#{k}"
				elsif (k=="end_time")
					t_sql="timestamp<=:#{k}"
				# elsif(k=="online_pay_id")
				# 	t_sql="online_pay_id in (#{v.join(',')})"
				else
					t_sql="#{k}=:#{k}"
				end

				sql="#{sql} and #{t_sql}"
			end

			sql
		end
end
