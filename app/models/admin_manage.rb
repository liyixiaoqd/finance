class AdminManage < ActiveRecord::Base
	has_many :admin_authority
	
	def get_country_str()
		if self.country=="ALL"
			Enumsable::COUNTRY_MAPPING_TO_DISPLAY.keys.join(",")
		else
			self.country
		end
	end


	def get_auth_str()
		auth_str=","
	
		self.admin_authority.each do |aa|
			if aa.status==true
				auth_str+=aa.no.to_s+","
			end
		end unless self.admin_authority.blank?

		auth_str
	end


	def self.valid_admin(admin_hash)
		name=admin_hash['admin_name']
		passwd=admin_hash['admin_passwd_encryption']

		#logger.info("#{name} - #{passwd}")
		am=AdminManage.find_by_admin_name(name)


		if am.present? && am.status=="normal" && am.admin_passwd==Digest::MD5.hexdigest("#{passwd}#{Settings.admin.passwd_key}")
			return am
		else
			logger.info("username or password is wrong!")
		end

		nil
	end

	def self.encry_passwd(passwd)
		Digest::MD5.hexdigest("#{passwd}#{Settings.admin.passwd_key}")
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