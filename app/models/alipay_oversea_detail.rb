class AlipayOverseaDetail
	include PayDetailable
	include AlipayDetailable
	attr_accessor :system,:amount,:description,:currency,:order_no

	#PAY_ALIPAY_OVERSEA_PARAMS=%w{system amount description currency order_no success_url notification_url}
	def initialize(online_pay)
		if !payparams_valid("alipay_oversea",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "alipay_oversea payparams valid failure!!"
		end

		define_var("alipay_oversea",online_pay)
	end

	def submit
		options = {
			'out_trade_no' => "#{@system}_#{@order_no}",
			'subject' => @description,
			'rmb_fee' => sprintf("%.2f", @amount),
			'return_url' => Settings.alipay_oversea.return_url,
			'notify_url' => Settings.alipay_oversea.notify_url,
			'service' => 'create_forex_trade',
			'_input_charset' => 'utf-8',
			'partner' => Settings.alipay_oversea.pid,
			'currency' => @currency
		}

		redirect_url="#{Settings.alipay_oversea.alipay_oversea_api_ur}?#{query_string(options,Settings.alipay_oversea.secret)}"

		response_code=method_url_response_code("get",redirect_url,true)
		if(response_code=="200" || response_code=="302")
			["success",redirect_url,"","false",""]
		else
			Rails.logger.info(redirect_url)
			["failure","","","","get alipay url failure,code:#{response_code}"]
		end
	end

	private 
		def spec_payparams_valid(online_pay)
			errmsg=''
			#if(online_pay['system']=='quaie')
			#	errmsg="alipay_oversea.system can not be quaie"
			if(online_pay['currency']!="EUR")
				errmsg="alipay_oversea.currency must be 'EUR'"	
			end

			if errmsg.blank?
				true
			else
				Rails.logger.info(errmsg)
				false
			end
		end
end