module RegisteHelper
	PAY_TYPE_MAPPING={
		'monthly' => '月结',
		'normal' => '正常'
	}

	def pay_type_mapping(pay_type)
		PAY_TYPE_MAPPING[pay_type]
	end
end
