module AlipayDetailable extend ActiveSupport::Concern
  
	def check_required_options(options, names)
		names.each do |name|
			Rails.logger.warn("Ailpay Warn: missing required option: #{name}") unless options.has_key?(name)
		end
	end

	def stringify_keys(hash)
		new_hash = {}
		hash.each do |key, value|
			new_hash[(key.to_s rescue key) || key] = value
		end    
		new_hash
  	end
	
	def query_string(options,secret)
		options.merge('sign_type' => 'MD5', 'sign' => generate_sign(options,secret)).map do |key, value|
			"#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
		end.join('&')
	end

	def generate_sign(params,secret)
		query = params.sort.map do |key, value|
			"#{key}=#{value}"
		end.join('&')
		Rails.logger.info(query)
		Digest::MD5.hexdigest("#{query}#{secret}")
	end

	def verify_sign?(params,secret)
		params = stringify_keys(params)
		params.delete('sign_type')
		sign = params.delete('sign')

		generate_sign(params,secret) == sign
	end

	def notify_verify?(params,pid,secret)
		valid_flag=false
		if verify_sign?(params,secret) 
			params = stringify_keys(params)
			valid_url="#{Settings.alipay_oversea.alipay_oversea_api_ur}?service=notify_verify&partner=#{pid}&notify_id=#{CGI.escape params['notify_id'].to_s}"
			if open(valid_url).read == 'true'
				Rails.logger.info("ALIPAY NOTIFY_VERIFY SUCCESS!!: #{valid_url}")
				valid_flag=true
			else
				if Settings.simulation.online_pay_verify=="true"
					valid_flag=true
				end

				Rails.logger.info("ALIPAY NOTIFY_VERIFY FAILURE!!: #{valid_url} , #{valid_flag}")
			end
		else
			Rails.logger.info("ALIPAY NOTIFY_VERIFY - verify_sign FAILURE!!")
		end

		valid_flag
	end
end