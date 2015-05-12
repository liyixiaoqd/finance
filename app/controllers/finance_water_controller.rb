class FinanceWaterController < ApplicationController
	protect_from_forgery :except => :modify

	# before_action :authenticate_admin!,:only=>:show

	include Paramsable
	
	def new
		@user=User.find(params['userid'])
	end

	def show
		@user=User.find(params['userid'])
		@finance_waters=@user.finance_water.page(params[:page])
	end

	def modify
		respond_to do |format|	
			unless params_valid("finance_submit",params)
				format.json { render json:{},status:400 }
				format.html {flash[:notice]="新增流水失败-系统验证错误";render :back}
				return 
			end

			ret_hash={
				'userid'=>params['userid'],
				'status'=>'failure',
				'reasons'=>[],
				'score'=>0.0,
				'e_cash'=>0.0,
				'waterno'=>''
			}
			user=nil
			begin
				ActiveRecord::Base.transaction do
					#use lock 
					user=User.lock().find_by_system_and_userid(params['system'],params['userid'])
					@user=user
					if(user.blank?)
						ret_hash['reasons']<<{'reason'=>"user is not exists!"}
						format.json {render json:ret_hash.to_json}
						format.html {flash[:notice]=ret_hash['reasons'];render :back}
						return
					end

					finance_water=new_finance_water_params(user,params)
					update_params={}
					if(finance_water.watertype=="score")
						update_params['score']=finance_water.new_amount
					elsif(finance_water.watertype=="e_cash")
						update_params['e_cash']=finance_water.new_amount
					end

					user.update_attributes(update_params) && finance_water.save
					if user.errors.any? || finance_water.errors.any?
						user.errors.full_messages.each do |msg|
							ret_hash['reasons']<<{'reason'=>msg}
						end

						finance_water.errors.full_messages.each do |msg|
							ret_hash['reasons']<<{'reason'=>msg}
						end
						raise "create finance_water failure"
					else 
						ret_hash['score']=user.score
						ret_hash['e_cash']=user.e_cash
						ret_hash['waterno']=finance_water.id
						ret_hash['status']='success'
					end
				end
			rescue => e
				logger.info("create finance_water failure! : #{e.message}")
			end

		
			format.json { render json:ret_hash.to_json }
			format.html {
				if ret_hash['status']=="success"
					redirect_to show_user_finance_water_path(user) 
				else
					redirect_to new_user_finance_water_path(user)
				end
			}
		end
	end

	private
		def new_finance_water_params(user,params)
			finance_water=user.finance_water.build()
			finance_water.system=params["system"]
			finance_water.channel=params["channel"]
			finance_water.userid=params["userid"]
			finance_water.symbol=params["symbol"]
			finance_water.amount=params["amount"]
			finance_water.operator=params["operator"]
			finance_water.operdate=params["datetime"]
			finance_water.watertype=params["watertype"]
			finance_water.reason=params["reason"]
			
			if(finance_water.watertype=='score')
				finance_water.old_amount=user.score
				if(finance_water.symbol=='Add')
					finance_water.new_amount=user.score+finance_water.amount
				elsif(finance_water.symbol=="Sub")
					finance_water.new_amount=user.score-finance_water.amount
				end
			elsif(finance_water.watertype=='e_cash')
				finance_water.old_amount=user.e_cash
				if(finance_water.symbol=='Add')
					finance_water.new_amount=user.e_cash+finance_water.amount
				elsif(finance_water.symbol=="Sub")
					finance_water.new_amount=user.e_cash-finance_water.amount
				end
			end
		
			finance_water	
		end
end
