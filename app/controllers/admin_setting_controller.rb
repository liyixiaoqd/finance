class AdminSettingController < ApplicationController
	def index
		@admin_manages=AdminManage.all.page(params[:page])
	end

	def show_authority
		@am=AdminManage.includes(:admin_authority).order("admin_authorities.describe asc").find_by_admin_name(params['admin_name'])
	end

	def new_authority
		@aa_hash={}

		aas=AccessAuthority.where("access_level is not null and is_interface=false and is_sign_in=true and controller!='SimulationController'").order("access_authorities.describe asc")

		aas.each do |aa|
			aa_user=AdminAuthority.find_by_admin_name_and_controller_and_action_and_no(params['admin_name'],aa.controller,aa.action,aa.access_level)
			if aa_user.blank?
				@aa_hash[aa.describe]=[false,aa.controller,aa.action]
			else
				@aa_hash[aa.describe]=[aa_user.status,aa.controller,aa.action]
			end
		end
		@admin_set_name=params['admin_name']
	end

	def modify_authority
		begin
			aa=AdminAuthority.find_by_admin_name_and_controller_and_action(params['admin_name'],params['auth_controller'],params['auth_action'])
			if aa.blank?
				admin=AdminManage.find_by_admin_name(params['admin_name'])
				access=AccessAuthority.find_by_controller_and_action(params['auth_controller'],params['auth_action'])

				if admin.blank? || access.blank?
					raise "获取用户、权限基础数据出错"
				end

				if access.access_level.blank?
					raise "权限基础数据异常!"
				end

				aa=admin.admin_authority.build 
				aa.admin_name=admin.admin_name
				aa.controller=params['auth_controller']
				aa.action=params['auth_action']
				aa.no=access.access_level
				aa.describe=access.describe
			end

			aa.status=params['status']
			aa.save!()

			if session[:admin]==params['admin_name']
				session[:admin_auth]=aa.admin_manage.get_auth_str()
				logger.info("reload session_auth:#{session[:admin_auth]}")
			end
		rescue=>e
			flash[:notice]=e.message
		end

		@admin_set_name=params['admin_name']
		redirect_to new_authority_admin_setting_path(params['admin_name'])
	end

	def new_country()
		@country_hash={}
		am_country_arr=[]
		@am=AdminManage.find_by_admin_name(params['admin_name'])
		am_country=@am.country
		am_country_arr=am_country.split(",") if am_country.present?
		logger.info("new_country: #{am_country_arr}")
		Enumsable::COUNTRY_MAPPING_TO_DISPLAY.each do |c|
			if am_country=="ALL"
				@country_hash[c[1]]=[true,c[0]]
			elsif am_country_arr.present? && am_country_arr.include?(c[0])
				@country_hash[c[1]]=[true,c[0]]
			else
				@country_hash[c[1]]=[false,c[0]]
			end
		end
	end

	def modify_country()
		@am=AdminManage.find_by_admin_name(params['admin_name'])
		new_country=""
		# 修改国家为全部或全部取消
		if params['country']==" "
			if params['status']=="false"
				new_country=""
			else
				new_country="ALL"
			end
		else
			#只可能为取消
			if @am.country=="ALL"
				Enumsable::COUNTRY_MAPPING_TO_DISPLAY.each do |c|
					if c[0]!=params['country'] && c[0]!=" "
						if new_country.blank?
							new_country=c[0]
						else
							new_country+=","+c[0]
						end
					end
				end
			else
				if params['status']=="true"
					if @am.country.blank?
						new_country=params['country']
					else
						new_country=@am.country+","+params['country']

						if new_country.split(",").size==Enumsable::COUNTRY_MAPPING_TO_DISPLAY.size-1
							new_country="ALL"
						end
					end
				else
					@am.country.split(",").each do |c|
						if c!=params['country']
							if new_country.blank?
								new_country=c
							else
								new_country+=","+c
							end
						end
					end
				end
			end
		end
		logger.info("new_country:#{new_country}")

		@am.update_attributes!(:country=>new_country)
		redirect_to new_country_admin_setting_path(params['admin_name'])
	end
end
