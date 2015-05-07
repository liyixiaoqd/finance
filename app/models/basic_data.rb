class BasicData < ActiveRecord::Base
	BASIC_DEFAULT_SETTING={
		"00A001"=>"30",
		"00A002"=>"24"
	}

	def self.get_value(basic_type,basic_sub_type,payway,paytype)
		value=BasicData.select(:value).find_by_basic_type_and_basic_sub_type_and_payway_and_paytype(basic_type,basic_sub_type,payway,paytype)['value']
		if value.blank?
			logger.info("BASIC NOT DEFINED AND USE DEFAULT VALUE")
			value=BASIC_DEFAULT_SETTING["#{basic_type}#{basic_sub_type}"]
		end

		value
	end
end
