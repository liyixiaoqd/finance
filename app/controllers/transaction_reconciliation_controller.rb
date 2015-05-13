class TransactionReconciliationController < ApplicationController
	# before_action :authenticate_admin!

	CONDITION_PARAMS=%w{payway paytype reconciliation_flag start_time end_time}
	# def index
	# 	@reconciliation_details=ReconciliationDetail.includes(:online_pay).all.page(params[:page])

	# 	respond_to do |format|
	# 		format.js { }
	# 		format.html { render :index }
	# 	end
	# end

	def index
		sql=sql_from_condition_filter(params)
		#logger.info(sql)
		@reconciliation_details=ReconciliationDetail.includes(:online_pay).where(sql,params).page(params[:page])
		# @reconciliation_details=Kaminari.paginate_array(@reconciliation_details).page(params[:page]).per(ReconciliationDetail::PAGE_PER)

		respond_to do |format|
			format.html { render :index }
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
