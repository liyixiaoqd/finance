class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.  	
	protect_from_forgery with: :exception

	force_ssl if: :ssl_required?
	before_action :authenticate_admin!

	rescue_from RuntimeError,with: :deny_access

	DENY_ACCESS_MESSAGE="无权限访问此功能,请确认用户!"

	REALM = Settings.authenticate.realm
 	SYSTEMS = {"finance_name" => Digest::MD5.hexdigest([Settings.authenticate.username,REALM,Settings.authenticate.passwd].join(":"))}


  	private
	  	def deny_access(e)
	  		if e.message==DENY_ACCESS_MESSAGE
	  			flash[:notice]=e.message
	  			redirect_to admin_manage_sign_index_path and return
	  		else
	  			raise e
	  		end
	  	end

		def authenticate_admin!
			unless Rails.env.production?
				logger.info("!!!!authenticate_admin.body:#{request.body.read}")
				logger.info("!!!!authenticate_admin.params:#{params}")
			end
			controller=params['controller'].camelize()+"Controller"
			action=params['action']

			sign_flag,interface_flag,need_level,digauth_flag=AccessAuthority.get_sign_interface_level_digauth(controller,action)



			if session[:admin].blank?
				if interface_flag 
					if digauth_flag
						interface_authenticate()
					end
				elsif sign_flag
					logger.info("please login in!!")
					redirect_to admin_manage_sign_in_path
				end
			else
				if session[:admin_level].blank?
					session[:admin_level]=AdminManage.get_authority(session[:admin])
				end

				if session[:admin_level]<need_level
					raise DENY_ACCESS_MESSAGE
				end
			end
			# if session[:admin].blank?		
			# 	#sign check
			# 	if AccessAuthority.isSignIn(controller,action)
			# 		logger.info("please login in!!")
			# 		redirect_to admin_manage_sign_in_path
			# 	end
			# else
			# 	#authority check
			# 	if session[:admin_level].blank?
			# 		session[:admin_level]=AdminManage.get_authority(session[:admin])
			# 	end

			# 	need_level=AccessAuthority.getAccessLevel(controller,action)

			# 	if session[:admin_level]<need_level
			# 		raise DENY_ACCESS_MESSAGE
			# 	end
			# end
		end

		def interface_authenticate
			authenticate_or_request_with_http_digest(REALM) do |system_name|
				#@system_name = system_name
				SYSTEMS[system_name]
			end
		end

		def ssl_required?
			controller=params['controller'].camelize()+"Controller"
			action=params['action']

			!Rails.env.development? && AccessAuthority.isDigauth(controller,action)
		end
end
