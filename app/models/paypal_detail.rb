class PaypalDetail
	include PayDetailable
	attr_accessor :ip,:country,:amount,:description,:currency,:order_no

	 SPEC_PARAMS_COUNTRY=%w(de nl gb at)
	#PAY_PAYPAL_PARAMS=%w{amount currency success_url abort_url order_no description ip country}
	def initialize(online_pay)
		if !payparams_valid("paypal",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "paypal payparams valid failure!!"
		end

		define_var("paypal",online_pay)
	end

	def submit
		if @country == "de"
			response = EXPRESS_GATEWAY_DE.setup_purchase( (@amount.to_f*100).round,
			:ip                => @ip,
			:currency          => @currency,
			:return_url        => Settings.paypal.return_url,
			:cancel_return_url => Settings.paypal.cancel_url,
			:items             => [ { :name => @order_no,
					    :amount   => price_in_cents(@amount),
					    :description => @description} ]
			)
		elsif @country == "nl"
			response = EXPRESS_GATEWAY_NL.setup_purchase( (@amount.to_f*100).round,
			:ip                => @ip,
			:currency          => @currency,
			:return_url        => Settings.paypal.return_url,
			:cancel_return_url => Settings.paypal.cancel_url,
			:items             => [ { :name => @order_no,
					    :amount   => price_in_cents(@amount),
					    :description => @description} ]
			)
		elsif @country == "gb"
			response = EXPRESS_GATEWAY_GB.setup_purchase( (@amount.to_f*100).round,
			:ip                => @ip,
			:currency          => @currency,
			:return_url        => Settings.paypal.return_url,
			:cancel_return_url => Settings.paypal.cancel_url,
			:items             => [ { :name => @order_no,
					    :amount   => price_in_cents(@amount),
					    :description => @description} ]
			)
		elsif @country == "at"
			response = EXPRESS_GATEWAY_AT.setup_purchase( (@amount.to_f*100).round,
			:ip                => @ip,
			:currency          => @currency,
			:return_url        => Settings.paypal.return_url,
			:cancel_return_url => Settings.paypal.cancel_url,
			:items             => [ { :name => @order_no,
					    :amount   => price_in_cents(@amount),
					    :description => @description} ]
			)
		end

		#return  flag   redirect_url    trade_no    is_credit    errmsg
		unless(response.token.blank?)
			redirect_url="#{Settings.paypal.paypal_api_uri}?cmd=_express-checkout&token=#{response.token}"
			["success",redirect_url,response.token,"true",""]
		else
			["failure","","","",response.message]
		end
	end

	def get_pay_details(trade_no)
		details=''
		begin
			Timeout::timeout(22){
				if @country == "de"
					details=EXPRESS_GATEWAY_DE.details_for(trade_no)
				elsif @country == "nl"
					details=EXPRESS_GATEWAY_NL.details_for(trade_no)
				elsif @country == "gb"
					details=EXPRESS_GATEWAY_GB.details_for(trade_no)
				elsif @country == "at"
					details=EXPRESS_GATEWAY_AT.details_for(trade_no)
				end
			}
			Rails.logger.info("get_pay_details:#{@country} - #{trade_no}:#{details.payer_id}")
			#Rails.logger.info("#{details.inspect}")
		rescue=>e
			raise "paypal_details_for TIME OUT!:#{e.message}"
		end

		details
	end

	def valid_credit_require(online_pay,request)
		message="success"
		unless(online_pay.remote_ip==request.remote_ip)
			message="ip not match! #{online_pay.ip} <=> #{request.remote_ip}"
		end

		message	
	end

	def process_purchase(online_pay)
		begin
			response=''
			Timeout::timeout(22){
				if online_pay.country == "de"
					response=EXPRESS_GATEWAY_DE.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"EUR"))
				elsif online_pay.country == "nl"
					response=EXPRESS_GATEWAY_NL.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"EUR"))
				elsif online_pay.country == "gb"
					response=EXPRESS_GATEWAY_GB.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"GBP"))
				elsif online_pay.country == "at"
					response=EXPRESS_GATEWAY_AT.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"EUR"))
				end
			}

			# Rails.logger.info("#{response.success?} , #{response.message}")
			#get reconciliation_id

			transactionid=nil
			transactionstatus=nil

			if response.success?
				begin
					transactionid=response.params["PaymentInfo"]["TransactionID"]
					transactionstatus=response.params["PaymentInfo"]["PaymentStatus"]
				rescue => e
					Rails.logger.info("get_transactionid_from_response failure #{e.message}")
					transactionid=nil
					transactionstatus=nil
				end
			end

			Rails.logger.info("process_purchase:#{transactionid}:#{transactionstatus}")
			[response.success?,response.message,transactionid,transactionstatus]
		rescue=>e
			Rails.logger.info("process_purchase expection: #{e.message}")
			[false,e.message,nil,nil]
		end
	end

	def is_succ_pay_by_call?(online_pay,call_time)
		starttime=((call_time+" UTC").to_time.utc-5*60-60).strftime("%Y-%m-%dT%H:%M:%SZ")
		endtime=((call_time+" UTC").to_time.utc+5*60).strftime("%Y-%m-%dT%H:%M:%SZ")
		rp=ReconciliationPaypal.new("TransactionSearch",online_pay.country)
		flag,message,reconciliation_id,callback_status=rp.has_pay_order(online_pay.credit_email,online_pay.amount,starttime,endtime)

		[flag,message,reconciliation_id,callback_status]
	end

	private 
		def spec_payparams_valid(online_pay)
			errmsg=''
			if(online_pay['system']=='quaie')
				errmsg="paypal.system can not be quaie"
			elsif(online_pay['currency']!="EUR" && online_pay['currency']!="GBP")
				errmsg="paypal.currency must be 'EUR' or 'GBP'"
			elsif( !SPEC_PARAMS_COUNTRY.include?(online_pay['country']) )
				errmsg="paypal.country must in #{SPEC_PARAMS_COUNTRY}"
			end

			if errmsg.blank?
				true
			else
				Rails.logger.info(errmsg)
				false
			end
		end

		def express_purchase_options(online_pay,currency)
			{
				:ip => online_pay.ip,
				:currency => currency,
				:token => online_pay.trade_no,
				:payer_id => online_pay.credit_pay_id
			}
		end
end 