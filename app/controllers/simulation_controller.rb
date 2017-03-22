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

	#模拟调用各个接口
	def index_interface_call
		@display_interface={
			"url"=>"http://",
			"method"=>"get",
			"auth_method"=>"http_digest",
			"username"=>"",
			"password"=>"",
			"token"=>"",
			"body"=>""
		}
	end

	def interface_call
		logger.info("interface_call into")

		@display_interface=params

		@res_body=""
		if params['url'].blank? || params['url'][0,4]!="http" || params['url'].size<10
			@res_body+="请输入以http开头的网址;;"
		end

		if params['method'].blank? || ["get","post"].include?(params['method'])==false
			@res_body+="请选择调用方式 get或post;;"
		end

		if ["http_basic","http_digest"].include?(params['auth_method'])
			if params['username'].blank? || params['password'].blank?
				@res_body+="此认证方式,需要输入 用户名,密码;;"
			end
		end

		if "token"==params['auth_method'] && params['token'].blank?
			@res_body+="此认证方式,需要输入 token;;"
		end

		if params['body'].present?
			begin
				params['body'].gsub!("\r\n","")
				JSON.parse( params['body'] )
			rescue=>e
				logger.info("json rescue: #{e.message}")
				logger.info("params: #{params['body']}")
				@res_body+="报文非json格式,请确认;;"
			end
		end

		if @res_body.present?
			logger.info("interface_call return #{@res_body}")
			@res_body="调用前校验失败: #{@res_body}"  
			render "index_interface_call"
			return
		end

		begin
			response=method_url_call_interface(
				params['method'],
				params['url'],
				params['auth_method'],
				params['username'],
				params['password'],
				params['token'],
				params['body']
			)

			if response.code[0]!="2"
				raise "http返回值异常 #{response.code}"
			end
		rescue=>e
			@res_body=e.message
			@res_body="调用中发生异常: #{@res_body}"  
			render "index_interface_call"
			return
		end

		begin
			@res_body=JSON.parse response.body
		rescue=>e
			@res_body=response.body
		end

		if @res_body.class.to_s=="String"
			@res_body=@res_body.force_encoding("UTF-8")
		end
		
		@res_body="调用正常,返回报文: #{@res_body}"  
		render "index_interface_call"
		# respond_to do |format|
		# 	format.js "alert(abc)"
		# end
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

		if params['system'].blank? || params['system']=="mypost4u"
			sim_user=User.find_by(username: "spec_username",system: "mypost4u")
			if sim_user.blank?
				sim_user=User.find_by(email: "fylee_ger@126.com",system: "mypost4u")
			end
		else
			sim_user=User.find_by(username: "#{params['system']}_spec_username",system: params['system'])
		end
		userid=sim_user.userid
		
		callpath="/pay/#{userid}/submit"
		
		simulate_order_no=create_pay_order_no(payway,new_serial)

		case payway
		when 'paypal' then simulate_params=init_paypal_submit_params(simulate_order_no,amount,request.remote_ip,params['order_type'],params['country']) 
		when 'sofort' then simulate_params=init_sofort_submit_params(simulate_order_no,amount) 
		when 'alipay_oversea' then simulate_params=init_alipay_oversea_submit_params(simulate_order_no,amount) 
		when 'alipay_transaction' then simulate_params=init_alipay_transaction_submit_params(simulate_order_no,amount)
		when 'oceanpayment_unionpay_b2c' then 
			simulate_params=init_oceanpayment_submit_params(simulate_order_no,amount,"unionpay_b2c",params)
			callpath="/pay/#{userid}/submit_post"
		when 'oceanpayment_unionpay_b2b' then 
			simulate_params=init_oceanpayment_submit_params(simulate_order_no,amount,"unionpay_b2b",params)
			callpath="/pay/#{userid}/submit_post"
		when 'oceanpayment_wechatpay' then 
			simulate_params=init_oceanpayment_submit_params(simulate_order_no,amount,"wechatpay",params)
			callpath="/pay/#{userid}/submit_post"
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
			if payway[0,12]=="oceanpayment"
				@res=res_result
				logger.info("res: [#{@res}]")
				#post method to pay must use page 
				render simulation_simulate_pay_post_path
			else
				#get method to pay
				redirect_to CGI.unescape(res_result['redirect_url'])
			end
		else
			flash[:notice]='please modify and try again!'
			render :action=>'index'
		end
	end

	def simulate_pay_credit
		trade_no=params['trade_no']
		amount=params['amount']
		userid=User.find_by(username: "spec_username",system: "mypost4u").userid
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

		def method_url_call_interface(method,url_path,auth_method,username,password,token,params={})
			uri = URI.parse(url_path)
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl =  uri.scheme == 'https' if url_path[0,5]=="https"
			if(method=="get")
				request = Net::HTTP::Get.new(uri.request_uri) 
			else
				request = Net::HTTP::Post.new(uri.request_uri) 
			end

			if auth_method=="http_digest"
				digest_auth = Net::HTTP::DigestAuth.new
				uri.user=username
				uri.password=password

				response = http.request(request)
				auth = digest_auth.auth_header uri, response['www-authenticate'], method.upcase
				request.add_field 'Authorization', auth
			elsif auth_method=="http_basic"
				request.basic_auth username,password
			elsif auth_method=="token"
				request.add_field 'Authorization', token
			end

			request.body=params
			response=http.request(request)
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
			when 'alipay_transaction' then order_no="alipay_transaction_#{calldate}_#{callnum}"
			when 'oceanpayment_unionpay_b2c' then order_no="oceanpayment_unionpay_b2c_#{calldate}_#{callnum}"
			when 'oceanpayment_unionpay_b2b' then order_no="oceanpayment_unionpay_b2b_#{calldate}_#{callnum}"
			when 'oceanpayment_wechatpay' then order_no="oceanpayment_wechatpay_#{calldate}_#{callnum}"
			else
				order_no="unmatch_#{payway}_#{calldate}_#{callnum}"
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

		def init_paypal_submit_params(order_no,amount,ip,order_type,country)
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
				'country'=>country,
				'order_type'=>order_type
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

		def init_oceanpayment_submit_params(order_no,amount,paytype,params)
			oceanpayment_submit_params={
				'system'=>params['system'].blank? ? "mypost4u" : params['system'],
				'payway'=>'oceanpayment',
				'paytype'=>paytype,
				'amount'=>amount,
				'order_no'=>order_no,
				'currency'=>'RMB',
				'logistics_name'=>'logistics_name',
				'description'=>"测试交易:订单号#{order_no}的寄送包裹费用",
				'success_url'=>"#{CALL_HOST}/simulation/callback_return",
				'notification_url'=>"#{CALL_HOST}/simulation/callback_notify",
				'quantity'=>1,
				'country'=>'de',
				'consumer_name'=>params['consumer_name'],
				'consumer_id'=>params['consumer_id'],
				'consumer_phone'=>params['consumer_phone'],
				'consumer_email'=>"#{params['consumer_id']}@hotmail.com",
				'company_name'=>params['company_name']
			}		

			init_online_pay_params.merge!(oceanpayment_submit_params)
		end

		def current_time_ymdHMS(format="")
			if (format.blank?)
				Time.zone.now.strftime("%Y-%m-%d %H:%M:%S")
			else
				Time.zone.now.strftime(format)
			end
		end
end
