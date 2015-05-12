class AdminManage < ActiveRecord::Base
	def self.valid_admin(admin_hash)
		name=admin_hash['admin_name']
		passwd=admin_hash['admin_passwd_encryption']

		logger.info("#{name} - #{passwd}")
		am=AdminManage.find_by_admin_name(name)


		if am.present? && am.status=="normal" && am.admin_passwd==Digest::MD5.hexdigest("#{passwd}#{Settings.admin.passwd_key}")
			return am
		else
			logger.info("#{passwd} == #{am.admin_passwd}")
		end

		nil
	end

	def self.get_authority(name)
		begin
			am=AdminManage.find_by_admin_name!(name)
			am.authority.to_i
		rescue => e
			logger.warn("#{name} get authority failure! #{e.message}")
			-1
		end
	end
end