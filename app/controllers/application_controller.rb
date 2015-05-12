class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	before_action :authenticate_admin!

	rescue_from RuntimeError,with: :deny_access

	DENY_ACCESS_MESSAGE="无权限访问此功能,请确认用户!"

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
			controller=params['controller'].camelize()+"Controller"
			action=params['action']

			if session[:admin].blank?		
				#sign check
				if AccessAuthority.isSignIn(controller,action)
					logger.info("please login in!!")
					redirect_to admin_manage_sign_in_path
				end
			else
				#authority check
				if session[:admin_level].blank?
					session[:admin_level]=AdminManage.get_authority(session[:admin])
				end

				need_level=AccessAuthority.getAccessLevel(controller,action)

				if session[:admin_level]<need_level
					raise DENY_ACCESS_MESSAGE
				end
			end
		end
end
