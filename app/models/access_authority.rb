class AccessAuthority < ActiveRecord::Base
	def self.get_sign_interface_level_digauth(controller,action)
		sign=true
		interface=false
		level=-1
		digauth=true

		record=AccessAuthority.select(:is_sign_in,:is_interface,:access_level,:is_digest_auth).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		else
			sign=record['is_sign_in']
			interface=record['is_interface']
			if record['access_level'].blank?
				level=-1
			else
				level=record['access_level'].to_i
			end
			digauth=record['is_digest_auth']
		end

		[sign,interface,level,digauth]
	end

	def self.isDigauth(controller,action)
		value=true

		record=AccessAuthority.select(:is_digest_auth).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		else
			value=record['is_digest_auth']
		end

		value
	end

	def self.isSignIn(controller,action)
		value=true
		record=AccessAuthority.select(:is_sign_in).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		else
			value=record['is_sign_in']
		end

		value
	end

	def self.isInterface(controller,action)
		value=false
		record=AccessAuthority.select(:is_interface).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		else
			value=record['is_interface']
		end

		value
	end

	def self.getAccessLevel(controller,action)
		value=-1
		record=AccessAuthority.select(:access_level).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		elsif record['access_level'].blank?
			value=-1
		else
			value=record['access_level'].to_i
		end

		value
	end

end
