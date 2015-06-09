class TransactionReconciliationController < ApplicationController
	# before_action :authenticate_admin!

	CONDITION_PARAMS=%w{payway paytype reconciliation_flag start_time end_time transactionid online_pay_id}
	# def index
	# 	@reconciliation_details=ReconciliationDetail.includes(:online_pay).all.page(params[:page])

	# 	respond_to do |format|
	# 		format.js { }
	# 		format.html { render :index }
	# 	end
	# end

	def index
		#logger.info(sql)
		unless (params['order_no'].blank?)
			op=OnlinePay.find_by_order_no(params['order_no'])
			unless op.blank?
				params['online_pay_id']=op.id
			end
		end
		
		sql=sql_from_condition_filter(params)
		@reconciliation_details=ReconciliationDetail.includes(:online_pay).where(sql,params).page(params[:page])
		
		# @reconciliation_details=Kaminari.paginate_array(@reconciliation_details).page(params[:page]).per(ReconciliationDetail::PAGE_PER)
		respond_to do |format|
			format.html { render :index }
			format.js
		end
	end

	def report
		payway=params['payway']
		paytype=params['paytype']
		start_time=params['start_time']
		end_time=params['end_time']

		if start_time.blank? || end_time.blank?
			@finance_summary=FinanceSummary.new(OnlinePay.current_time_format("%Y-%m-%d",-1),OnlinePay.current_time_format("%Y-%m-%d",0))
		else
			@finance_summary=FinanceSummary.new(start_time,end_time,1)
			condition=""
			condition="and payway='#{payway}'" unless payway.blank?
			condition+=" and paytype='#{paytype}'" unless paytype.blank?
			@finance_summary.setAmountAndNum!(condition)
			logger.info(@finance_summary.output)
		end

		respond_to do |format|
			format.html { render :report }
			format.js
		end
	end

	private 
		def sql_from_condition_filter(params)
			sql=""
			index=1

			params.each do |k,v|
				next if v.blank? 
				next unless CONDITION_PARAMS.include?(k)
				
				if( k=="start_time")
					t_sql="timestamp>=:#{k}"
				elsif (k=="end_time")
					t_sql="timestamp<=:#{k}"
				else
					t_sql="#{k}=:#{k}"
				end

				if(index==1)
					sql=t_sql
				else
					sql="#{sql} and #{t_sql}"
				end

				index=index+1
			end

			sql
		end
end
