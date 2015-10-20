class RegisteController < ApplicationController
	protect_from_forgery :except => :create

	include Paramsable

	CONDITION_PARAMS=%w{system username min_amount max_amount email}
	# before_action :authenticate_admin!,:only=>:index
	# before_action :web_use_interface_authenticate

	def index
		sql=sql_from_condition_filter(params)
		#logger.info(sql)
		@users=User.where(sql,params).page(params[:page])
		#@users=Kaminari.paginate_array(@reconciliation_details).page(params[:page]).per(ReconciliationDetail::PAGE_PER)

		respond_to do |format|
			format.js { }
			format.html { render :index }
		end
	end

	def show
		@user=User.find_by_system_and_userid(params['system'],params['userid'])
		if @user.blank?
			flash[:notice]="#{params['userid']} not exists in #{params['system']} !"
			redirect_to registe_index_path and return
		end
		# respond_to do |format|
		# 	unless params_valid("registe_show",params)
		# 		format.json{ render json:{},status:400 and return }
		# 		format.html { 
		# 			flash[:notice]="system valid failure!"
		# 			redirect_to registe_index_path and return
		# 		}
		# 	end

		# 	@user=User.find_by_system_and_userid(params['system'],params['userid'])		
		# 	format.json{
		# 		if @user.blank?
		# 			render json:{},status:400 and return
		# 		else
		# 			render json:@user.to_json and return
		# 		end
		# 	}
		# 	format.html{
		# 		if @user.blank?
		# 			flash[:notice]="#{params['userid']} not exists in #{params['system']} !"
		# 			redirect_to registe_index_path and return
		# 		else 
		# 			return
		# 		end
		# 	}
		# end
	end

	def create
		#valid input params
		render json:{},status:400 and return unless params_valid("registe_create",params)

		ret_hash={
			'system'=>params['system'],
			'channel'=>params['channel'],
			'userid'=>params['userid'],
			'status'=>'failure',
			'reasons'=>[],
			'water_no'=>[]
		}
		
		begin
			ActiveRecord::Base.transaction do
				user=new_user_params(params)
				user.save && user.create_init_finance(params["scoreInitReason"],params["accountInitReason"])
				
				if user.errors.any?
					user.errors.full_messages.each do |msg|
						ret_hash['reasons']<<{'reason'=>msg}
					end
					raise "create user failure"
				else
					user.finance_water.each do |f|
						ret_hash['water_no']<<f.id.to_s
					end
					ret_hash['status']='success'
				end
			end
		rescue=>e
			logger.info("create use failure! #{e.message}")
			ret_hash['reasons']<<e.message
		end

		render json:ret_hash.to_json 
	end
	
	def obtain
		render json:{},status:400 and return unless params_valid("registe_obtain",params)

		ret_hash={
			'userid'=>params['userid'],
			'type'=>[]
		}

		user=User.find_by_system_and_userid(params['system'],params['userid'])
		if user.blank?
			render json:{},status:400 and return
		end

		ret_hash['type']<<{'watertype'=>'score','amount'=>user['score']}
		ret_hash['type']<<{'watertype'=>'e_cash','amount'=>user['e_cash']}

		render json:ret_hash.to_json
	end

	private
		def new_user_params(params)
			user=User.new()
			user.system=params["system"]
			user.channel=params["channel"]
			user.userid=params["userid"]
			user.username=params["username"]
			user.email=params["email"]
			user.e_cash=params["accountInitAmount"]
			user.score=params["scoreInitAmount"]
			user.operator=params["operator"]
			user.operdate=params["datetime"]
			
			if params["user_type"].present?
				user.user_type=params["user_type"]
				user.address=params["address"]
				user.vat_no=params["vat_no"]
				user.pay_type=params["pay_type"]
				user.pay_limit=params["pay_limit"]
			end

			user
		end

		def sql_from_condition_filter(params)
			sql=""
			index=1

			symbol=params['symbol']

			params.each do |k,v|
				next if v.blank? 
				next unless CONDITION_PARAMS.include?(k)

				if( k=="min_amount")
					if symbol.present? && symbol=="e_cash"
						t_sql="e_cash>=:#{k}"
					elsif symbol.present? && symbol=="score"
						t_sql="score>=:#{k}"
					end
				elsif (k=="max_amount")
					if symbol.present? && symbol=="e_cash"
						t_sql="e_cash<=:#{k}"
					elsif symbol.present? && symbol=="score"
						t_sql="score<=:#{k}"
					end
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
