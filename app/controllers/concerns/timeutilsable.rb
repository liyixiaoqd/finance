module Timeutilsable extend ActiveSupport::Concern
	def isTime?(time)
		ret_flag=true
		begin
			t=time.to_time
			ret_flag=false if t.blank?
		rescue=>e
			ret_flag=false
		end

		ret_flag
	end

	def isNotTime?(time)
		!isTime?(time)
	end
end