class AdminManageController < ApplicationController

	def sign_index
	end

	def sign_in
		if request.method=="GET"
			@admin=AdminManage.new()
			return
		end

		if params['admin']['admin_name']=="admin" && params['admin']['admin_passwd']=="passwd"
			session['admin']="dddd"

			redirect_to admin_manage_sign_index_path and return
		end

		@admin=AdminManage.new(admin_param_params)
	end

	def sign_out
		session['admin']=nil

		redirect_to admin_manage_sign_index_path
	end

	private
		def admin_param_params  
			params.require(:admin).permit(:admin_name,:admin_passwd)  
		end  
end
