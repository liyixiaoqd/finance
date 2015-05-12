class AdminManageController < ApplicationController
	def sign_index
	end

	def sign_in
		if request.method=="GET"
			if session['admin'].blank?
				@admin=AdminManage.new()
				return
			else
				redirect_to admin_manage_sign_index_path and return
			end
		else

			am=AdminManage.valid_admin(valid_admin_param_params)

			unless am.blank?
				session[:admin]=am.admin_name
				session[:admin_level]=am.authority.to_i
				redirect_to admin_manage_sign_index_path and return
			end

			@admin=AdminManage.new(new_admin_param_params)
		end
		
	end

	def sign_out
		session['admin']=nil

		redirect_to admin_manage_sign_in_path
	end

	private
		def valid_admin_param_params  
			params.require(:admin).permit(:admin_name,:admin_passwd_encryption)
		end  

		def new_admin_param_params  
			params.require(:admin).permit(:admin_name)  
		end  
end
