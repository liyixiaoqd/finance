require 'concerns/net_http_auth.rb'

class SimulationController < ApplicationController
	protect_from_forgery :except => [:simulate_post]

	# before_action :authenticate_admin!,:only=>[:index,:index_reconciliation]

	CALL_HOST=Settings.simulation.call_host

	@@simulation_num=0

	def index
	end

	def index_reconciliation
	end

	def simulate_reconciliation
		payment_system=params['payment_system']
		start_time=params['start_time']
		end_time=params['end_time']
		page_size=params['page_size']

		case payment_system
		when "alipay_transaction" then format="%Y-%m-%d %H:%M:%S"
		when "alipay_oversea" then format="%Y%m%d"
		when "paypal" then format="%Y-%m-%dU%H:%M:%SZ"
		else
			format="%Y-%m-%d %H:%M:%S"
		end

		start_time=CGI.escape(start_time.to_time.strftime(format))
		end_time=CGI.escape(end_time.to_time.strftime(format))
		
		callpath="#{CALL_HOST}/pay/#{payment_system}/get_reconciliation?start_time=#{CGI.escape(start_time)}&end_time=#{CGI.escape(end_time)}&page_size=#{page_size}"

		response=method_url_call("get",callpath,"false",{}) 

		render :text=>"#{response.body}"
	end

	def simulate_finance_modify
		userid=params['userid']
		score=params['score'].to_f
		symbol=params['symbol']
		watertype=params['watertype']

		callpath="#{CALL_HOST}/finance_water/#{userid}/modify"
		score_params=score_params(userid,score,symbol,watertype)

		response=method_url_call("post",callpath,"false",score_params) 

		render :text=>"#{response.body}"
	end

	def simulate_registe
		userid=params['userid']
		score=params['score'].to_f
		e_cash=params['e_cash'].to_f
		user_type=params['user_type']

		callpath="#{CALL_HOST}/registe"
		registe_params=registe_params(userid,score,e_cash,user_type)
		logger.info("#{registe_params.inspect}")
		response=method_url_call("post",callpath,"false",registe_params) 

		render :text=>"#{response.body}"				
	end

	def simulate_pay
		payway=params['payway']
		amount=params['amount']
		if params['serial'].blank?
			new_serial=0
		else
			new_serial=params['serial'].to_i
		end

		logger.info("payway:#{payway}")

		userid="552b461202d0f099ec000033"
		callpath="/pay/#{userid}/submit"
		
		simulate_order_no=create_pay_order_no(payway,new_serial)

		case payway
		when 'paypal' then simulate_params=init_paypal_submit_params(simulate_order_no,amount,request.remote_ip) 
		when 'sofort' then simulate_params=init_sofort_submit_params(simulate_order_no,amount) 
		when 'alipay_oversea' then simulate_params=init_alipay_oversea_submit_params(simulate_order_no,amount) 
		when 'alipay_transaction' then simulate_params=init_alipay_transaction_submit_params(simulate_order_no,amount)
		else
			simulate_params={}
		end

		logger.info("simulate_params:#{simulate_params.inspect}")

		# request = Net::HTTP::Post.new(uri.request_uri) 
		# request.set_form_data(simulate_params)
		# logger.info("SIMULATION CALL !!")
		# response=http.request(request)
		response=method_url_call("post","#{CALL_HOST}#{callpath}",false,simulate_params)
		res_result=JSON.parse(response.body)
		logger.info("SIMULATION CALL END !!")
		#logger.info("body:#{response.body}\nresult:#{res_result}")
		unless (res_result['redirect_url'].blank?)
			redirect_to CGI.unescape(res_result['redirect_url'])
		else
			flash[:notice]='please modify and try again!'
			render :action=>'index'
		end
	end

	def simulate_pay_credit
		trade_no=params['trade_no']
		amount=params['amount']
		userid="552b461202d0f099ec000033"
		callpath="/pay/#{userid}/submit_creditcard"
		ip=request.remote_ip
		
		# uri = URI.parse("#{CALL_HOST}#{callpath}")
		# logger.info("path:#{callpath}")
		# http = Net::HTTP.new(uri.host, uri.port)

		# request = Net::HTTP::Post.new(uri.request_uri) 
		# request.set_form_data(credit_params(trade_no,amount,ip))
		# logger.info("call!!")
		# response=http.request(request)
		response=method_url_call("post","#{CALL_HOST}#{callpath}",false,credit_params(trade_no,amount,ip))
		res_result=JSON.parse(response.body)
		logger.info("body:#{response.body}\nresult:#{res_result}")
		unless (res_result['redirect_url'].blank?)
			redirect_to CGI.unescape(res_result['redirect_url'])
		else
			render :text=>"code:#{response.code}</br>body:#{response.body}</br>result:#{res_result}"
		end
	end

	def callback_return
		@params=params

		# @params.each do |k,v|
		# 	logger.info("#{k} = #{v}")
		# end
	end

	def callback_notify
		begin
			@params=JSON.parse request.body.read
			logger.info("CALLBACK_NOTIFY JSON_PARSE: #{@params}")
		rescue=>e
			@params=params
			logger.info("CALLBACK_NOTIFY NOT JSON_PARSE #{e.message}: #{@params}")
		end

		@params.each do |k,v|
			logger.info("#{k} = #{v}")
		end

		render json:{status: "success"}
	end

	def simulate_get
		call_url=params['call_url']
		# response=method_url_call("get",call_url,"false")

		# logger.info("SIMULATE_GET:#{response.code}:#{response.body}")
		# render :text=>"#{response.code}:#{response.body}"
		redirect_to call_url
	end

	def simulate_post
		call_url=params['call_url']
		method_url_call("post",call_url,"false") and return
		# response=method_url_call("post",call_url,"false")

		# logger.info("SIMULATE_POST:#{response.code}:#{response.body}")
		# render :text=>"#{response.code}:#{response.body}"
	end

	def self.get_simulation_num
		@@simulation_num
	end

	private
		def method_url_call(method,url_path,https,params={})
			digest_auth = Net::HTTP::DigestAuth.new
			uri = URI.parse(url_path)
			logger.info("sim:#{url_path}")
			uri.user=Settings.authenticate.username
			uri.password=Settings.authenticate.passwd

			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl =  uri.scheme == 'https' if url_path[0,5]=="https"

			if(method=="get")
				request = Net::HTTP::Get.new(uri.request_uri) 
			else
				request = Net::HTTP::Post.new(uri.request_uri) 
			end

			response = http.request(request)
			auth = digest_auth.auth_header uri, response['www-authenticate'], method.upcase
			request.add_field 'Authorization', auth

			unless(method=="get")
				if(params.blank?)
					request.set_form_data(method_params(method))
				else
					request.set_form_data(params)
				end
			end

			response=http.request(request)
			logger.info("sim response:#{response.code}")
			response	
		end
	
		def method_params(method)
			{
				"notify_id"=>"4e5606af1c34d98e86228566c18954262a",
				 "notify_type"=>"trade_status_sync", 
				 "sign"=>"046894a5ef53ee6ea294b13332456dae",
				  "trade_no"=>"2015040900001000050051921095", 
				  "total_fee"=>"195.63", 
				  "out_trade_no"=>"mypost4u_alipay_oversea_20150429_001", 
				  "currency"=>"EUR", 
				  "notify_time"=> current_time_ymdHMS(), 
				  "trade_status"=>"WAIT_SELLER_SEND_GOODS", 
				  "sign_type"=>"MD5"
			}
		end

		def credit_params(trade_no,amount,ip)
			{
				'payway'=>'paypal',
				'paytype'=>'',
				'trade_no'=>trade_no,
				'amount'=>amount,
				'currency'=>'EUR',
				'ip'=>ip,
				'brand' => 'visia', 
				'number' => '1111111111',
				'verification_value' => '315',
				'month' => '12',
				'year' => '15',
				'first_name' => 'ly',
				'last_name' => 'xxx'	
			}
		end

		def score_params(userid,score,symbol,watertype)
			oper=[{
					'symbol'=>symbol,
					'amount'=>score,
					'pay_amount'=>score,
					'reason'=>"#{watertype} #{symbol} #{score}",
					'watertype'=>watertype,
					'is_pay'=>'N',
					'order_no'=>''
				}].to_json

			{
				'system'=>'mypost4u',
				'channel'=>'web',
				'userid'=>userid,
				'operator'=>'system',
				'datetime'=>current_time_ymdHMS(),
				'oper'=>oper
			}
		end

		def registe_params(userid,score,e_cash,user_type)
			{
				'system'=>'mypost4u',
				'channel'=>'web',
				'userid'=>userid,
				'username'=>'testname',
				'email'=>'testname@126.com',
				'accountInitAmount'=>e_cash,
				'accountInitReason'=>'init e_cash',
				'scoreInitAmount'=>score,
				'scoreInitReason'=>'init score',
				'operator'=>'system',
				'datetime'=>current_time_ymdHMS(),
				'user_type'=>user_type,
				'address'=>'test_address',
				'vat_no'=>'DE12345',
				'pay_type'=>'monthly',
				'pay_limit'=>'-10000'
			}
		end

		def create_pay_order_no(payway,new_serial)
			if (@@simulation_num==new_serial)
				@@simulation_num=@@simulation_num+1
			else
				@@simulation_num=new_serial
			end

			callnum=sprintf("%03d",@@simulation_num)
			calldate=current_time_ymdHMS("%Y%m%d")

			case payway
			when 'paypal' then order_no="paypal_#{calldate}_#{callnum}"
			when 'sofort' then order_no="sofort#{calldate}#{callnum}" 
			when 'alipay_oversea' then order_no="alipay_oversea_#{calldate}_#{callnum}"
			when 'alipay_transaction' then order_no="alipay_transaction_#{calldate}_#{callnum}"
			else
				order_no="nopayway_#{calldate}_#{callnum}"
			end

			order_no
		end

		def init_online_pay_params
			{
				'system'=>'',
				'payway'=>'',
				'paytype'=>'',
				'userid'=>'',
				'amount'=>'',
				'currency'=>'',
				'order_no'=>'',
				'success_url'=>'',
				'notification_url'=>'',
				'notification_email'=>'',
				'abort_url'=>'',
				'timeout_url'=>'',
				'ip'=>'',
				'description'=>'',
				'country'=>'',
				'quantity'=>'',
				'logistics_name'=>'',
				'send_country'=>'de'
			}
		end

		def init_paypal_submit_params(order_no,amount,ip)
			paypal_submit_params={
				'system'=>'mypost4u',
				'payway'=>'paypal',
				'paytype'=>'',
				'amount'=>amount,
				'currency'=>'EUR',
				'order_no'=>order_no,
				'description'=>"TESTMODE:#{order_no}",
				'ip'=>ip,
				'success_url'=>"#{CALL_HOST}/simulation/callback_return",
				'abort_url'=>"#{CALL_HOST}/simulation/callback_return",
				'notification_url'=>"#{CALL_HOST}/simulation/callback_notify",
				'country'=>'de'
			}

			init_online_pay_params.merge!(paypal_submit_params)
		end

		def init_sofort_submit_params(order_no,amount)
			sofort_submit_params={
				'system'=>'mypost4u',
				'payway'=>'sofort',
				'paytype'=>'',
				'amount'=>amount,
				'currency'=>'EUR',
				'order_no'=>order_no,
				'success_url'=> "#{CALL_HOST}/simulation/callback_return",
				'abort_url'=> "#{CALL_HOST}/simulation/callback_return",
				'notification_url'=>"#{CALL_HOST}/simulation/callback_notify",
				'timeout_url'=> "#{CALL_HOST}/simulation/callback_return",
				'country'=>'de'
			}		
			init_online_pay_params.merge!(sofort_submit_params)
		end

		def init_alipay_oversea_submit_params(order_no,amount)
			alipay_oversea_submit_params={
				'system'=>'mypost4u',
				'payway'=>'alipay',
				'paytype'=>'oversea',
				'amount'=>amount,
				'currency'=>'EUR',
				'order_no'=>order_no,
				'description'=>"TESTMODE:#{order_no}",
				'success_url'=>"#{CALL_HOST}/simulation/callback_return",
				'notification_url'=>"#{CALL_HOST}/simulation/callback_notify"
			}		
			init_online_pay_params.merge!(alipay_oversea_submit_params)
		end

		def init_alipay_transaction_submit_params(order_no,amount)
			alipay_transaction_submit_params={
				'system'=>'mypost4u',
				'payway'=>'alipay',
				'paytype'=>'transaction',
				'amount'=>amount,
				'order_no'=>order_no,
				'logistics_name'=>'logistics_name',
				'description'=>"测试交易:订单号#{order_no}的寄送包裹费用",
				'success_url'=>"#{CALL_HOST}/simulation/callback_return",
				'notification_url'=>"#{CALL_HOST}/simulation/callback_notify",
				'quantity'=>1
			}		
			init_online_pay_params.merge!(alipay_transaction_submit_params)
		end

		def current_time_ymdHMS(format="")
			if (format.blank?)
				Time.now.strftime("%Y-%m-%d %H:%M:%S")
			else
				Time.now.strftime(format)
			end
		end
end
