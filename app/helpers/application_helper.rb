module ApplicationHelper
	include Enumsable

	def dynamic_send_country_select_tag()
		#{}"['',''],['德国','de'],['荷兰','nl'],['中国','cn'],['奥地利','at'],['英国','gb']"
		send_country={}

 		if session[:admin_country].present?
 			session[:admin_country].split(",").each do |c|
				dis=COUNTRY_MAPPING_TO_DISPLAY[c]
				send_country[dis]=c if dis.present?
			end
 		else
 			send_country['未知']='unknow'
 		end
		send_country
	end

	def isAuthority(name)
		if session[:admin_auth].blank?
			false 
		else
			if session[:admin_auth].include?(",#{name},")
				true
			else
				false
			end
		end
		# if name=="用户明细"
		# 	controller="OnlinePayController"
		# 	action="index"
		# else
		# 	Rails.logger.info("name:#{name}")
		# 	false and return
		# end

		# AdminAuthority.isAuthority!(session[:admin],controller,action)
	end
end
