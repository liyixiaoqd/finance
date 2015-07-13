class AdminAuthority < ActiveRecord::Base
	belongs_to :admin_manage

	def self.isAuthority!(admin_name,controller,action)
		aa=AdminAuthority.find_by_admin_name_and_status_and_controller_and_action(admin_name,true,controller,action)

		if aa.blank?
			false
		else
			true
		end
	end
end
