module PayDetailable extend ActiveSupport::Concern
	PAY_PAYPAL_PARAMS=%w{amount currency success_url abort_url order_no description ip country notification_url}
	PAY_SOFORT_PARAMS=%w{system country currency order_no amount success_url notification_url abort_url timeout_url}
	PAY_ALIPAY_OVERSEA_PARAMS=%w{system amount description currency order_no success_url notification_url}
	PAY_ALIPAY_TRANSACTION_PARAMS=%w{system quantity amount logistics_name description order_no success_url notification_url}
	
	def payparams_valid(detail_name,online_pay)
		valid_flag=true;
		match_name="PAY_"+detail_name.upcase+"_PARAMS"
		params_val=eval(match_name)
		case match_name
			when 'PAY_PAYPAL_PARAMS' then valid_flag=check_payparams(params_val,online_pay)
			when 'PAY_SOFORT_PARAMS' then valid_flag=check_payparams(params_val,online_pay)
			when 'PAY_ALIPAY_OVERSEA_PARAMS' then valid_flag=check_payparams(params_val,online_pay)
			when 'PAY_ALIPAY_TRANSACTION_PARAMS' then valid_flag=check_payparams(params_val,online_pay)
			else
				valid_flag=false
				Rails.logger.warn("match #{valid_flag} #{detail_name} - #{match_name}")
		end
		Rails.logger.info("valid #{valid_flag}:#{match_name}")
		valid_flag
	end

	def define_var(detail_name,online_pay)
		# Rails.logger.info(online_pay.inspect)
		match_name="PAY_"+detail_name.upcase+"_PARAMS"
		params_val=eval(match_name)
		params_val.each do |param|
			#Rails.logger.info("@#{param}=online_pay['#{param}']")
			eval("@#{param}=online_pay['#{param}']")
		end
	end

	def method_url_response(method,url_path,https_boolean,params={})
		uri = URI.parse(url_path)
		http = Net::HTTP.new(uri.host, uri.port)

		http.use_ssl =  uri.scheme == 'https' if (https_boolean==true || url_path[0,5].upcase=="HTTPS")
		http.read_timeout=20
		if(method=="get")
			request = Net::HTTP::Get.new(uri.request_uri) 
		else
			request = Net::HTTP::Post.new(uri.request_uri) 
			request.set_form_data(params)
		end

		#test !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		response=nil
		begin
			Timeout::timeout(22){
				response=http.request(request)
			}
		rescue => e
			Rails.logger.info("CALL URL:#{url_path} EXPECTION:#{e.message}")
			response=MyResponse.new
		end
		Rails.logger.info("url.code:#{response.code}")
		response		
	end

	def method_url_response_code(method,url_path,https_boolean,params={})
		method_url_response(method,url_path,https_boolean,params).code
	end

	def method_url_success?(method,url_path,https_boolean,params={})
		ret=true
		begin
			response=method_url_response(method,url_path,https_boolean,params)
			ret = (response.code=="200" && JSON.parse(response.body)['status']=="success")
		rescue => e
			Rails.logger.info("method_url wrong:#{e.message}")
			ret=false
		end
		
		ret
	end

	def price_in_cents(price)
		(price*100).round
	end

	def current_time_format(format="",step=0)
		if (format.blank?)
			format="%Y-%m-%d %H:%M:%S"
		end

		if step!=0
			(Time.now+step.day).strftime(format)
		else
			Time.now.strftime(format)
		end
	end
	
	# methods defined here are going to extend the class, not the instance of it
	module ClassMethods
		def current_time_format(format="",step=0)
			if (format.blank?)
				format="%Y-%m-%d %H:%M:%S"
			end

			if step!=0
				(Time.now+step.day).strftime(format)
			else
				Time.now.strftime(format)
			end
		end

		def redirect_url_replace(method,redirect_url,ret_hash={})
			new_redirect_url=""
			if(method=="get")
				params_url=ret_hash.map do |key,value|
					"#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
				end.join("&")
				new_redirect_url=redirect_url+"?"+params_url
			else
				new_redirect_url=redirect_url
			end

			new_redirect_url
		end
	end

	private
		def check_payparams(valid_params,online_pay)
			valid_params.each do |param|
				if online_pay[param].blank?
					Rails.logger.info("missing payparam:#{param}")
					return false
				end
			end

			true			
		end
end