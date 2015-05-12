module OnlinePayHelper
	STATUS_MAPPING={
		'submit'=>'支付中-请求提交',
		'failure_submit'=>'支付失败-请求提交失败',
		'submit_credit'=>'支付中-请求(信用卡)提交',
		'intermediate_notify'=>'支付中-异步回写中',
		'success_notify'=>'支付成功-异步回写成功',
		'cancel_notify'=>'支付失败-异步回写取消',
		'failure_notify'=>'支付失败-异步回写失败',
		'success_credit'=>'支付成功-请求(信用卡)成功',
		'failure_credit'=>'支付失败-请求(信用卡)失败',
	}

	PAYWAY_PAYTYPE_MAPPING={
		'AlipayOversea'=>'支付宝-海外',
		'AlipayTransaction'=>'支付宝-国内',
		'Paypal'=>'paypal',
		'Sofort'=>'sofort'
	}

	def status_mapping(status)
		STATUS_MAPPING[status.to_s]
	end

	def payway_paytype_mapping(payway_type)
		PAYWAY_PAYTYPE_MAPPING[payway_type]
	end
end
