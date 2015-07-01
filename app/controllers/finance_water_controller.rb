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

					online_pay=new_online_pay_each(user,finance_each,params)
					unless online_pay.blank?
						online_pay.save

						if online_pay.errors.any?
							online_pay.errors.full_messages.each do |msg|
								ret_hash['reasons']<<{'reason'=>msg}
							end
							raise "create finance_water - online_pay failure"
						end
						logger.info("online_pay record save success!!!! #{online_pay.id}")
						reconciliation_detail=new_reconciliation_detail_each(online_pay,params)
						reconciliation_detail.save

						if reconciliation_detail.errors.any?
							reconciliation_detail.errors.full_messages.each do |msg|
								ret_hash['reasons']<<{'reason'=>msg}
							end
							raise "create finance_water - reconciliation_detail failure"
						end
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
			ret_hash['waterno']=[]
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


	def refund
		unless params_valid("finance_water_refund",params)
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		ret_hash={
			'status'=>'failure',
			'reasons'=>[]
		}

		begin
			ActiveRecord::Base.transaction do
				online_pay=OnlinePay.find_by_payway_and_paytype_and_order_no(params['payway'],params['paytype'],params['order_no'])
				if online_pay.blank?
					raise "无此订单号#{params['order_no']}"
				elsif online_pay.status[0,7]!="success"
					raise "支付状态#{online_pay.status}不允许进行退费操作!"
				elsif online_pay.amount!=params['amount'].to_f
					raise "支付金额不匹配#{online_pay.amount}<>#{params['amount']}不允许进行退费操作!"
				end

				reconciliation_detail=new_reconciliation_detail_each(online_pay,params)
				reconciliation_detail.save

				if reconciliation_detail.errors.any?
					reconciliation_detail.errors.full_messages.each do |msg|
						ret_hash['reasons']<<{'reason'=>msg}
					end
					raise "create reconciliation_detail failure"
				end

				ret_hash['status']='success'
			end
		rescue => e
			logger.info("create reconciliation_detail failure! : #{e.message}")
			ret_hash['reasons']<<{'reason'=>e.message} if ret_hash['reasons'].blank?
			logger.info("FINANCE.MODIFY_WEB RET HASH:#{ret_hash}")
		end

		render json:ret_hash.to_json
	end

	private
		def new_online_pay_each(user,finance_each,params)
			if finance_each['is_pay']=="Y"
				if finance_each['order_no'].blank?
					raise "支付交易订单号不可为空"
				end
				if finance_each['symbol']!="Sub"
					raise "支付交易操作符只能为减"
				end

				unless OnlinePay.find_by_payway_and_paytype_and_order_no(finance_each["watertype"],'',finance_each["order_no"]).blank?
					raise "已存在此支付记录#{finance_each["order_no"]},不可重复操作!"
				end

				online_pay=user.online_pay.build()
				online_pay.system=params['system']
				online_pay.channel=params['channel']
				online_pay.userid=user.userid
				online_pay.payway=finance_each["watertype"]
				online_pay.paytype=""
				online_pay.amount=finance_each["amount"]
				online_pay.order_no=finance_each["order_no"]

				if finance_each["watertype"]=="score"
					online_pay.payway="score"
					online_pay.status="success_score"
				elsif finance_each["watertype"]=="e_cash"
					online_pay.payway="e_cash"
					online_pay.status="success_e_cash"
				end
				online_pay.reason=finance_each["reason"]
				online_pay.trade_no=online_pay.order_no
				online_pay.reconciliation_id=online_pay.order_no
				online_pay
			else
				nil
			end
		end

		def new_reconciliation_detail_each(online_pay,params)
			reconciliation_detail=online_pay.build_reconciliation_detail
			reconciliation_detail.payway=online_pay.payway
			reconciliation_detail.paytype=online_pay.paytype
			reconciliation_detail.batch_id=OnlinePay.current_time_format("%Y%m%d")+"_001"
			reconciliation_detail.transaction_date=OnlinePay.current_time_format("%Y-%m-%d")
			reconciliation_detail.timestamp=params["datetime"]
			reconciliation_detail.transactionid=online_pay.reconciliation_id
			reconciliation_detail.transaction_status='SUCC'
			reconciliation_detail.reconciliation_flag='2'
			reconciliation_detail.amt=online_pay.amount
			reconciliation_detail.netamt=0.0
			reconciliation_detail.feeamt=0.0

			reconciliation_detail
		end

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
