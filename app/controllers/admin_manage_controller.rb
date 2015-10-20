class AdminManageController < ApplicationController
	def sign_index
		@finance_summary=FinanceSummary.new(OnlinePay.current_time_format("%Y-%m-%d",-1),OnlinePay.current_time_format("%Y-%m-%d",-1))
		logger.info(@finance_summary.output())

		if isAuthority('12')
			@notices=Notice.get_details_by_num(5)
		end
		# @data=OnlinePay.current_time_format("%Y-%m-%d",0)
		# begdata=OnlinePay.current_time_format("%Y-%m-%d",-1)

		# @online_pay_num,@online_pay_amount_sum=OnlinePay.get_count_sum_by_day_condition(begdata,@data,"")
		# @online_pay_succ_num,@online_pay_succ_amount_sum=OnlinePay.get_count_sum_by_day_condition(begdata,@data,"status_succ")
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
			flash[:notice]=''
			am=AdminManage.valid_admin(valid_admin_param_params)

			unless am.blank?
				session[:admin]=am.admin_name
				# session[:admin_level]=am.authority.to_i
				session[:admin_country]=am.get_country_str()

				session[:admin_auth]=am.get_auth_str()

				redirect_to admin_manage_sign_index_path and return
			end

			@admin=AdminManage.new(new_admin_param_params)
			flash[:notice]="用户名或密码不匹配,请重新输入"
		end
		
	end

	def sign_out
		logout()

		redirect_to admin_manage_sign_in_path
	end

	def passwd_new
	end

	def passwd_modify
		old_passwd=params['old_passwd']
		new_passwd=params['new_passwd']
		new_passwd_confirm=params['new_passwd_confirm']
		message=''

	  	if (old_passwd=="")
	  		message='请输入旧密码'
	  	elsif(new_passwd=="")
			message="请输入新密码"
		elsif (new_passwd!=new_passwd_confirm)
			message="新密码输入不一致"
		elsif (new_passwd==old_passwd)
			message="新旧密码输入一致"
		else
			begin
				am=AdminManage.valid_admin({'admin_name'=>session['admin'],'admin_passwd_encryption'=>old_passwd})
				if am.blank?
					message="旧密码输入错误,请重新输入"
				else
					am.with_lock do
						am.admin_passwd=AdminManage.encry_passwd(new_passwd)
						am.update_attributes!({})
					end
				end
			rescue => e
				message=e.message
			end
		end

		if message.blank?
			message='密码修改成功,请重新登入'
			logout()
			flash[:notice]=message
			redirect_to admin_manage_sign_in_path and return
		else
			flash[:notice]=message
			redirect_to admin_manage_passwd_new_path and return
		end
	end

	private
		def valid_admin_param_params  
			params.require(:admin).permit(:admin_name,:admin_passwd_encryption)
		end  

		def new_admin_param_params  
			params.require(:admin).permit(:admin_name)  
		end  

		def logout
			if session[:admin].present?
				session[:admin]=nil
				# session[:admin_level]=nil
				session[:admin_country]=nil
			end
		end
end
