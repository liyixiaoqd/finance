require 'csv'

class FinanceWaterController < ApplicationController
	include FinanceWaterHelper

	protect_from_forgery :except => :modify

	# before_action :authenticate_admin!,:only=>:show

	include Paramsable
	
	def new
		@user=User.find(params['id'])
	end

	def show
		@user=User.find(params['id'])
		@finance_waters=@user.finance_water.page(params[:page])
	end

	def export
		user=User.includes(:finance_water).find(params['id'])

		csv_string = CSV.generate do |csv|
			csv << ["用户名", user.username,'',"注册E-Mail",user.email]
			csv << ["电子现金", user.e_cash,'',"积分",user.score] 	
			csv << []
			csv << ["流水类型", "起始","变化", "终止", "来源","操作时间"]
			user.finance_water.each do |fw|
				csv << [watertype_mapping(fw.watertype),fw.old_amount,"#{symbol_mapping(fw.symbol)} #{fw.amount}",
				              fw.new_amount,fw.operator,fw.operdate]
			end
		end
		
		send_data csv_string,:type => 'text/csv ',:disposition => "filename=财务流水明细_#{user.username}.csv"
	end

	def modify			
		unless params_valid("finance_water_modify",params)
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		ret_hash={
			'userid'=>params['userid'],
			'status'=>'failure',
			'reasons'=>[],
			'score'=>0.0,
			'e_cash'=>0.0,
			'waterno'=>[]
		}

		user=nil
		begin
			ActiveRecord::Base.transaction do
				#use lock 
				user=User.lock().find_by_system_and_userid(params['system'],params['userid'])
				logger.info(user.blank?)
				if(user.blank?)
					ret_hash['reasons']<<{'reason'=>"user is not exists!"}
					render json:ret_hash.to_json and return
				end

				finance_arrays=JSON.parse params['oper']

				if(finance_arrays.blank? || finance_arrays.size<1)
					raise "no finance_water oper!!!"
				end

				# finance_water=new_finance_water_params(user,params)
				for finance_each in finance_arrays
					finance_water=new_finance_water_each(user,finance_each,params)

					if(finance_water.watertype=="score")
						user.score=finance_water.new_amount
					elsif(finance_water.watertype=="e_cash")
						user.e_cash=finance_water.new_amount
					end

					finance_water.save
					if finance_water.errors.any?
						finance_water.errors.full_messages.each do |msg|
							ret_hash['reasons']<<{'reason'=>msg}
						end
						raise "create finance_water failure"
					end
					ret_hash['waterno']<<finance_water.id
				end

				user.update_attributes({})
				if user.errors.any? 
					user.errors.full_messages.each do |msg|
						ret_hash['reasons']<<{'reason'=>msg}
					end
					raise "update user attributes failure"
				end  

				ret_hash['score']=user.score
				ret_hash['e_cash']=user.e_cash
				ret_hash['status']='success'
			end
		rescue => e
			logger.info("create finance_water failure! : #{e.message}")
			ret_hash['reasons']<<{'reason'=>e.message} if ret_hash['reasons'].blank?
			logger.info("FINANCE.MODIFY RET HASH:#{ret_hash}")
		end

		render json:ret_hash.to_json
	end

	def modify_web	
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
				logger.info(user.blank?)
				if(user.blank?)
					ret_hash['reasons']<<{'reason'=>"user is not exists!"}
					flash[:notice]=ret_hash['reasons'];redirect_to :back and return
				end
				@user=user
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
			ret_hash['reasons']<<{'reason'=>e.message} if ret_hash['reasons'].blank?
			logger.info("FINANCE.MODIFY_WEB RET HASH:#{ret_hash}")
		end

	
		if ret_hash['status']=="success"
			redirect_to show_user_finance_water_path(user) and return 
		else
			flash[:notice]=ret_hash['reasons']
			redirect_to new_user_finance_water_path(user) and return 
		end
	end

	private
		def new_finance_water_each(user,finance_each,params)
			finance_water=user.finance_water.build()
			finance_water.system=params["system"]
			finance_water.channel=params["channel"]
			finance_water.userid=params["userid"]
			finance_water.operator=params["operator"]
			finance_water.operdate=params["datetime"]

			finance_water.symbol=finance_each["symbol"]
			finance_water.amount=finance_each["amount"]
			finance_water.watertype=finance_each["watertype"]
			finance_water.reason=finance_each["reason"]
			
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

		def new_finance_water_params(user,params)
			finance_water=user.finance_water.build()
			finance_water.system=params["system"]
			finance_water.channel=params["channel"]
			finance_water.userid=params["userid"]
			finance_water.operator=params["operator"]
			finance_water.operdate=params["datetime"]

			finance_water.symbol=params["symbol"]
			finance_water.amount=params["amount"]
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
