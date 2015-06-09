class PaypalDetail
	include PayDetailable
	attr_accessor :ip,:country,:amount,:description,:currency,:order_no

	 SPEC_PARAMS_COUNTRY=%w(de nl gb)
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
		end

		#return  flag   redirect_url    trade_no    is_credit    errmsg
		unless(response.token.blank?)
			redirect_url="#{Settings.paypal.paypal_api_uri}?cmd=_express-checkout&token=#{response.token}"
			["success",redirect_url,response.token,"true",""]
		else
			["failure","","","",response.message]
		end
	end

	def get_pay_details!(online_pay)
		if online_pay.country == "de"
			details=EXPRESS_GATEWAY_DE.details_for(online_pay.trade_no)
		elsif online_pay.country == "nl"
			details=EXPRESS_GATEWAY_NL.details_for(online_pay.trade_no)
		elsif online_pay.country == "gb"
			details=EXPRESS_GATEWAY_GB.details_for(online_pay.trade_no)
		end
		Rails.logger.info("get_pay_details:#{online_pay.country}:#{details.payer_id}")
		
		online_pay.credit_pay_id = details.payer_id
		online_pay.credit_first_name = details.params["first_name"]
		online_pay.credit_last_name = details.params["last_name"]
	end

	def valid_credit_require(online_pay,request)
		message="success"
		unless(online_pay.remote_ip==request.remote_ip)
			message="ip not match! #{online_pay.ip} <=> #{request.remote_ip}"
		end

		message	
	end

	def process_purchase(online_pay)
		if online_pay.country == "de"
			response=EXPRESS_GATEWAY_DE.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"EUR"))
		elsif online_pay.country == "nl"
			response=EXPRESS_GATEWAY_NL.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"EUR"))
		elsif online_pay.country == "gb"
			response=EXPRESS_GATEWAY_GB.purchase(price_in_cents(online_pay.amount), express_purchase_options(online_pay,"GBP"))
		end

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

		[response.success?,response.message,transactionid,transactionstatus]
	end

	private 
		def spec_payparams_valid(online_pay)
			errmsg=''
			if(online_pay['currency']!="EUR" && online_pay['currency']!="GBP")
				errmsg="paypal.currency must be 'EUR' or 'GBP'"
				Rails.logger.info(errmsg)
			elsif( !SPEC_PARAMS_COUNTRY.include?(online_pay['country']) )
				errmsg="paypal.country must in #{SPEC_PARAMS_COUNTRY}"
				Rails.logger.info(errmsg)
			end

			if errmsg.blank?
				true
			else
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