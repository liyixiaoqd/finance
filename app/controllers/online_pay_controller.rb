require 'csv'

class OnlinePayController < ApplicationController
	protect_from_forgery :except => :submit
	before_action :check_send_country,only: [:index,:export_index]
	include Paramsable,OnlinePayHelper
	
	CONDITION_PARAMS=%w{payway paytype reconciliation_flag start_time end_time reconciliation_id order_no user_id system send_country online_pay_status}
	# before_action :authenticate_admin!,:only=>[:show,:show_single_detail]
	def index
		if (params['username'].present? || params['email'].present? )
			users=nil
			if params['username'].present? && params['email'].present?
				users=User.where("username=? and email=?",params['username'],params['email']) 
			elsif params['username'].present?
				users=User.where("username=?",params['username']) 
			elsif params['email'].present?
				users=User.where("email=?",params['email']) 
			else
				logger.info("no match?  #{params['username']},#{params['email']}")
			end

			if users.blank?
				return
			else
				params['user_id']=[]
				users.each do |u|
					params['user_id']<<u.id
				end
			end
		end

		sql=sql_from_condition_filter(params)
		@online_pay=OnlinePay.includes(:user).where(sql,params).order("created_at desc").page(params[:page])
		# @reconciliation_details=Kaminari.paginate_array(@reconciliation_details).page(params[:page]).per(ReconciliationDetail::PAGE_PER)
		respond_to do |format|
			format.html { render :index }
			format.js
		end
	end

	def export_index
		if (params['username'].present? || params['email'].present? )
			users=nil
			if params['username'].present? && params['email'].present?
				users=User.where("username=? and email=?",params['username'],params['email']) 
			elsif params['username'].present?
				users=User.where("username=?",params['username']) 
			elsif params['email'].present?
				users=User.where("email=?",params['email']) 
			else
				logger.info("no match?  #{params['username']},#{params['email']}")
			end

			if users.blank?
				flash[:notice]="无可导出记录"
				redirect_to index_online_pay_path and return
			else
				params['user_id']=[]
				users.each do |u|
					params['user_id']<<u.id
				end
			end
		end

		sql=sql_from_condition_filter(params)
		if sql.blank?
			flash[:notice]="无可导出记录"
			redirect_to index_online_pay_path and return
		end

		online_pay=OnlinePay.includes(:user).where(sql,params).order("created_at desc")

		csv_string = CSV.generate do |csv|
			csv << ["导出工号", session[:admin],"导出时间", OnlinePay.current_time_format("%Y-%m-%d %H:%M:%S")]
			csv << []
			csv << ["用户名", "交易号", "金额","货币", "状态", "支付类型与子类型","订单号/补款号","交易日期","备注","交易完成日期","交易来源系统","包裹发送国家","注册E-Mail"]
			online_pay.each do |op|
				out_arr=[op.user.username,op.reconciliation_id,op.amount,op.get_convert_currency(),
				                status_mapping(op.status),
				                payway_paytype_mapping(op.payway.camelize + op.paytype.camelize),
				                op.order_no,op.created_at,op.reason]
				if op.reconciliation_detail.blank?
					out_arr += ['']
				else
					out_arr += [op.reconciliation_detail.timestamp]
				end
				out_arr += [status_mapping(op.status),op.send_country,op.user.email]

				csv << out_arr
			end
		end

		send_data csv_string,:type => 'text/csv ',:disposition => "filename=交易明细_#{OnlinePay.current_time_format("%Y%m%d%H%M%S")}.csv"
	end
	
	def show
		@user=User.find(params['userid'])
		@online_pays=@user.online_pay.order(created_at: :desc).page(params[:page])
	end

	def show_single_detail
		@online_pay=OnlinePay.includes(:user).find(params['online_pay_id'])
		render layout: false
	end

	def export
		user=User.includes(:online_pay).find(params['userid'])

		csv_string = CSV.generate do |csv|
			csv << ["用户名", user.username,'',"注册E-Mail",user.email]
			csv << ["电子现金", user.e_cash,'',"积分",user.score] 	
			csv << []
			csv << ["交易号", "金额","货币", "状态", "支付类型与子类型","订单号/补款号","备注"]
			user.online_pay.each do |op|
				csv << [op.reconciliation_id,op.amount,op.get_convert_currency(),
				              status_mapping(op.status),
				              payway_paytype_mapping(op.payway.camelize + op.paytype.camelize),
				              op.order_no,op.reason]
			end
		end
		
		send_data csv_string,:type => 'text/csv ',:disposition => "filename=支付明细_#{user.username}.csv"
	end

	def submit
		#logger.info(params.inspect)
		render json:{},status:400 and return unless params_valid("online_pay_submit",params)
		ret_hash={
			'redirect_url'=>'',
			'trade_no'=>'',
			'is_credit'=>''
		}

		online_pay=nil
		pay_detail=nil

		begin
		#先产生order_no
			user=User.find_by_system_and_userid(params['system'],params['userid'])
			if(user.blank?)
				render json:{},status:400 and return
			end

			logger.info("ONLINE PAY SUBMIT LOCK USER START:#{user.username} - #{params['order_no']}")
			user.with_lock do 				
				online_pay=new_online_pay_params(user,params,request)
				# if(online_pay.status=='failure_submit')
				# 	logger.warn("no user:#{online_pay.userid} pay record save!")
				# 	render json:{},status:400 and return
				# end
				online_pay.save!
			end
			logger.info("ONLINE PAY SUBMIT LOCK USER END:#{user.username} - #{online_pay.order_no} - #{online_pay.id}")

			# logger.info("ONLINE PAY SUBMIT LOCK ONLINE_PAY START:#{online_pay.id} - #{online_pay.order_no}")
			# online_pay.with_lock do 
			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
			flag,online_pay.redirect_url,online_pay.trade_no,online_pay.is_credit,message=pay_detail.submit()
			# if online_pay.paytype=="transaction"
			# 	flag,online_pay.redirect_url,online_pay.trade_no,online_pay.is_credit,message=pay_detail.submit_direct()
			# else
			#  	flag,online_pay.redirect_url,online_pay.trade_no,online_pay.is_credit,message=pay_detail.submit()
			# end

			logger.info("#{flag} - #{online_pay.redirect_url} - #{online_pay.trade_no} - #{message}")

			unless(flag=="success")
				online_pay.set_status!("failure_submit",message)
			end
			#alipay trade_no is nil so use  system_orderno
			if(online_pay.trade_no.blank? && flag=="success")
				#online_pay.trade_no="finance_#{online_pay.created_at.strftime("%y%m%d%H%M%S") }_#{online_pay.id}"
				online_pay.trade_no="#{online_pay.system}_#{online_pay.order_no}_#{Time.now.to_datetime.strftime '%Q'}"
			end
			online_pay.update_attributes!({})

			OrderNoToTradeNo.create!({
				payway: online_pay.payway,
				paytype: online_pay.paytype,
				order_no: online_pay.order_no,
				trade_no: online_pay.trade_no
			}) unless online_pay.trade_no.blank?

			ret_hash['redirect_url']=CGI.escape(online_pay.redirect_url)
			ret_hash['trade_no']=online_pay.trade_no
			ret_hash['is_credit']=online_pay.is_credit
			# end
			# logger.info("ONLINE PAY SUBMIT LOCK ONLINE_PAY END:#{online_pay.id} - #{online_pay.order_no}")
		rescue => e
			#failure also save pay record!!
			logger.info("online_pay create or call failure! : #{e.message}")
			unless (online_pay.blank?)
				online_pay.set_status!("failure_submit",e.message)
				online_pay.save
			end
			render json:{},status:400 and return
		end

		logger.info("ONLINE_PAY SUBMIT RET:#{ret_hash}")
		render json:ret_hash.to_json
	end

	# def  submit_creditcard
	# 	render json:{},status:400 and return unless params_valid("online_pay_submit_creditcard",params)
	# 	ret_hash={
	# 		'status'=>'failure',
	# 		'status_reason'=>''
	# 	}

	# 	OnlinePay.transaction do  	#lock table_row
	# 		online_pay=OnlinePay.get_online_pay_instance(params['payway'],params['paytype'],params,["submit_credit","failure_credit"],true,true)
	# 		render json:{},status:400  and return if online_pay.blank?
			
	# 		begin
	# 			supplement_online_pay_credit_params!(online_pay,params)

	# 			pay_detail=OnlinePay.get_instance_pay_detail(online_pay)
	# 			message=pay_detail.valid_credit_require(online_pay,request)
	# 			unless(message=="success")
	# 				raise "require valid failure! #{message}"
	# 			end

	# 			online_pay.set_status!("success_credit","")
	# 			online_pay.save!()
	# 			flag,message,online_pay.reconciliation_id,online_pay.callback_status=pay_detail.process_purchase(online_pay)
					
	# 			if flag==true
	# 				#update reconciliation_id
	# 				ret_hash['status']="success"
	# 				online_pay.save!()
	# 			else
	# 				ret_hash['status_reason']=message
	# 				raise "#{message}"
	# 			end	
	# 		rescue => e
	# 			#failure also save pay record!!	
	# 			logger.info("submit_creditcard online_pay failure! : #{e.message}")
	# 			#online_pay.set_status!("failure_credit",e.message)
	# 			unless (online_pay.blank?)
	# 				online_pay.update_attributes(:status=>"failure_credit",:reason=>e.message)
	# 			end
	# 		end
	# 	end

	# 	render json:ret_hash.to_json
	# end

	def get_bill_from_payment_system
		payment_system=params['payment_system']
		start_time=CGI.unescape(params['start_time'])
		end_time=CGI.unescape(params['end_time'])
		page_size=params['page_size']

		case payment_system
		when "alipay_transaction" then  reconciliation=ReconciliationAlipayTransaction.new("account.page.query",page_size,start_time,end_time,1000)
		when "alipay_oversea" then  reconciliation=ReconciliationAlipayOversea.new("forex_compare_file",start_time,end_time)
			# if payment_system_sub=="transaction"
			# 	reconciliation=ReconciliationAlipayTransaction.new("account.page.query","","",10)
			# else
			# 	nil
			# end
		when "paypal" then reconciliation=ReconciliationPaypal.new("TransactionSearch",start_time,end_time,"de")
		else
			render :text=>"wrong payment_system #{payment_system}" and return
		end

		#call interface  and   finance reconciliation
		message=reconciliation.finance_reconciliation()

		render :text=>message
	end

	private 
		def exists_online_pay(params)
			ol_p=OnlinePay.lock.find_by_system_and_payway_and_paytype_and_order_no(params['system'],params['payway'],params['paytype'],params['order_no'])
			if(ol_p.blank?)
				nil
			else
				if ol_p.status=="failure_submit" || ol_p.status=="submit" || ol_p.status=="cancel_notify" || ol_p.status=="failure_credit"
					ol_p
				else
					raise "#{params['order_no']}.status:#{ol_p.status} can not be repeat call!!!"
				end
			end
		end

		def new_online_pay_params(user,params,request)
			online_pay=exists_online_pay(params)
			if online_pay.blank?
				# user=User.find_by_system_and_userid(params['system'],params['userid'])
				# if(user.blank?)
				# 	online_pay=OnlinePay.new()
				# 	online_pay.set_status!("failure_submit","user not exists")
				# else
				online_pay=user.online_pay.build()
				online_pay.set_status!("submit","")
				# end
			else
				online_pay.set_status!("submit","")
			end

			online_pay.system=params.delete('system')
			online_pay.channel=params.delete('channel')
			online_pay.userid=params.delete('userid')
			online_pay.payway=params.delete('payway')
			online_pay.paytype=params.delete('paytype')
			online_pay.amount=params.delete('amount')

			online_pay.currency=params.delete('currency')

			online_pay.order_no=params.delete('order_no')
			online_pay.success_url=params.delete('success_url')
			online_pay.notification_url=params.delete('notification_url')
			online_pay.notification_email=params.delete('notification_email')
			online_pay.abort_url=params.delete('abort_url')
			online_pay.timeout_url=params.delete('timeout_url')
			online_pay.ip=params.delete('ip')
			online_pay.description=params.delete('description')
			online_pay.country=params.delete('country')
			online_pay.quantity=params.delete('quantity')
			online_pay.logistics_name=params.delete('logistics_name')
			online_pay.send_country=params.delete('send_country')
			online_pay.other_params=params.inspect

			online_pay.remote_host=request.remote_host
			online_pay.remote_ip=request.remote_ip
			online_pay.rate_amount=online_pay.amount
			online_pay.actual_amount=0.0

			online_pay.set_channel!()
			online_pay.set_is_credit!()
			online_pay.set_currency!()
			online_pay.set_country!()
			online_pay.set_ip!(request.remote_ip)

			online_pay
		end

		def supplement_online_pay_credit_params!(online_pay,params)
			online_pay.credit_brand=params['brand']
			online_pay.credit_number=params['number']
			online_pay.credit_verification=params['verification_value']
			online_pay.credit_month=params['month']
			online_pay.credit_year=params['year']
			online_pay.credit_first_name=params['first_name']
			online_pay.credit_last_name=params['last_name']
		end

		def sql_from_condition_filter(params)
			sql=""
			index=1

			params.each do |k,v|
				next if v.blank? 
				next unless CONDITION_PARAMS.include?(k)

				if(k=="start_time")
					t_sql="left(created_at,10)>=:#{k}"
				elsif (k=="end_time")
					t_sql="left(created_at,10)<=:#{k}"
				elsif(k=="user_id")
					t_sql="user_id in (#{v.join(',')})"
				elsif(k=="online_pay_status")
					if v=="succ"
						t_sql="status like 'success%'"
					elsif v=="fail"
						t_sql="status like 'failure%' and status!='failure_notify_third'"
					elsif v=="fail_third"
						t_sql="status = 'failure_notify_third'"
					else
						t_sql="status not like 'failure%' and status not like 'success%'"
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
