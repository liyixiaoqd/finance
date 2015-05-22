class AdminManageController < ApplicationController
	def sign_index
		@data=OnlinePay.current_time_format("%Y-%m-%d",0)
		begdata=OnlinePay.current_time_format("%Y-%m-%d",-1)

		@online_pay_num,@online_pay_amount_sum=OnlinePay.get_count_sum_by_day_condition(begdata,@data,"")
		@online_pay_succ_num,@online_pay_succ_amount_sum=OnlinePay.get_count_sum_by_day_condition(begdata,@data,"status_succ")
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
		if session[:admin].present?
			session[:admin]=nil
			session[:admin_level]=nil
		end
		
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
