class AccessAuthority < ActiveRecord::Base
	def self.get_sign_interface_level(controller,action)
		sign=true
		interface=false
		level=99

		record=AccessAuthority.select(:is_sign_in,:is_interface,:access_level).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		else
			sign=record['is_sign_in']
			interface=record['is_interface']
			level=record['access_level'].to_i
		end

		[sign,interface,level]
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
		value=99
		record=AccessAuthority.select(:access_level).find_by_controller_and_action(controller,action)

		if record.blank?
			logger.info("#{controller}.#{action} not exists?!")
		else
			value=record['access_level'].to_i
		end

		value
	end
end
