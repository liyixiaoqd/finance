module Paramsable extend ActiveSupport::Concern
	REGISTE_CREATE_PARAMS=%w{system channel userid username email accountInitAmount scoreInitAmount operator datetime}
	FINANCE_SUBMIT_PARAMS=%w{system channel userid symbol amount operator reason datetime watertype}
	ONLINE_PAY_SUBMIT_PARAMS=%w{system payway paytype userid amount currency order_no success_url notification_url notification_email abort_url timeout_url ip description country quantity logistics_name}
	ONLINE_PAY_SUBMIT_CREDITCARD_PARAMS=%w{payway paytype trade_no amount currency ip brand number verification_value month year first_name last_name}
	
	def params_valid(action_name,params)
		valid_flag=true;
		match_name=action_name.upcase+"_PARAMS"
		params_val=eval(match_name)
		case match_name
			when 'REGISTE_CREATE_PARAMS' then valid_flag=check_params(params_val,params)
			when 'FINANCE_SUBMIT_PARAMS' then valid_flag=check_params(params_val,params)
			when 'ONLINE_PAY_SUBMIT_PARAMS' then valid_flag=check_params(params_val,params)
			when 'ONLINE_PAY_SUBMIT_CREDITCARD_PARAMS' then valid_flag=check_params(params_val,params)
			else
				valid_flag=false
				logger.warn("match #{valid_flag} #{action_name} - #{match_name}")
		end
		logger.info("valid #{valid_flag}:#{match_name}")
		valid_flag
	end

	private
		def check_params(valid_params,params)
			valid_params.each do |param|
				unless params.has_key?(param)
					logger.info("missing param:#{param}")
					return false
				end
			end			
		end
end
