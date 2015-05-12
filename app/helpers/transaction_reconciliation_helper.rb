module TransactionReconciliationHelper
	RECONCILIATIONDETAIL_FLAG_MAPPING = {
		'0' => '未对账',
		'1' => '对账失败',
		'2' => '对账成功'
	}

	def reconciliation_flag_mapping(reconciliation_flag)
		RECONCILIATIONDETAIL_FLAG_MAPPING[reconciliation_flag.to_s]
	end
end
