class AccessAuthority < ActiveRecord::Base
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
