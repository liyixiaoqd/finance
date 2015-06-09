module FinanceWaterHelper
	WATERTYPE_MAPPING={
		'e_cash' => '电子现金',
		'score' => '积分'
	}

	SYMBOL_MAPPING={
		'Add' => '+',
		'Sub' => '-'
	}

	def watertype_mapping(watertype)
		WATERTYPE_MAPPING[watertype.to_s]
	end

	def symbol_mapping(symbol)
		SYMBOL_MAPPING[symbol.to_s]
	end


	# def FinanceWaterHelper.watertype_mapping(watertype)
	# 	WATERTYPE_MAPPING[watertype.to_s]
	# end
	
	# def FinanceWaterHelper.watertype_mapping(watertype)
	# 	SYMBOL_MAPPING[symbol.to_s]
	# end
end
