class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	before_action :authenticate_admin!

  	private
	def authenticate_admin!
		if session[:admin].blank?
			logger.info("please login in!!")
			redirect_to admin_manage_sign_in_path
		end
	end
end
