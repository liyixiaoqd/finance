module TransactionReconciliationHelper
	RECONCILIATIONDETAIL_FLAG_MAPPING = {
		'0' => '未对账',
		'1' => '对账失败',
		'2' => '对账成功',
		'3' => '非财务系统交易'
	}

	def reconciliation_flag_mapping(reconciliation_flag)
		RECONCILIATIONDETAIL_FLAG_MAPPING[reconciliation_flag.to_s]
	end

	def get_period(invoice)
		if invoice.amount<0 # && invoice.begdate!=invoice.enddate
			"#{invoice.begdate} to #{invoice.enddate}"
		else
			""
		end
	end
end
