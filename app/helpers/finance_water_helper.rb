module FinanceWaterHelper
	WATERTYPE_MAPPING={
		'e_cash' => '电子现金',
		'score' => '积分'
	}
	def watertype_mapping(watertype)
		WATERTYPE_MAPPING[watertype.to_s]
	end
end
