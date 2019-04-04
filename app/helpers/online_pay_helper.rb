module OnlinePayHelper
	STATUS_MAPPING={
		'submit'=>'支付中-请求提交',
		'failure_submit'=>'支付失败-请求提交失败',
		'submit_credit'=>'支付中-请求(信用卡)提交',
		'intermediate_notify'=>'支付中-异步回写中',
		'success_notify'=>'支付成功-异步回写成功',
		'cancel_notify'=>'支付失败-异步回写取消',
		'failure_notify'=>'支付失败-异步回写失败',
		'failure_notify_third'=>'支付成功-调用原系统失败',
		'success_credit'=>'支付成功-请求(信用卡)成功',
		'failure_credit'=>'支付失败-请求(信用卡)失败',
		'success_score'=>'支付成功-积分支付',
		'success_e_cash'=>'支付成功-电子现金支付'
	}

	STATUS_MAPPING_TO_TYPE={
		'submit'=>'manual_payment',
		'failure_submit'=>'manual_payment',
		'submit_credit'=>'manual_payment',
		'intermediate_notify'=>'manual_payment',
		'success_notify'=>'success',
		'cancel_notify'=>'manual_payment',
		'failure_notify'=>'manual_payment',
		'failure_notify_third'=>'recall_notify',
		'success_credit'=>'success',
		'failure_credit'=>'manual_payment',
		'success_score'=>'success',
		'success_e_cash'=>'success'
	}

	PAYWAY_PAYTYPE_MAPPING={
		'AlipayOversea'=>'支付宝-海外',
		'AlipayTransaction'=>'支付宝-国内',
		'Paypal'=>'paypal',
		'Sofort'=>'sofort',
		'Score'=>'积分',
		'ECash'=>'电子现金',
		"OceanpaymentUnionpayB2c"=>"银联-b2c(钱海)",
		"OceanpaymentUnionpayB2b"=>"银联-b2b(钱海)",
		"OceanpaymentWechatpay"=>"微信(钱海)",
		"OceanpaymentAlipay"=>"支付宝(钱海)",
		"WechatMobilePay" => "微信(移动支付)",
		"HelipayWechatpay"=>"微信(合利宝)",
		"HelipayAlipay"=>"支付宝(合利宝)",
		"HelipayUnionpayB2c"=>"银联-b2c(合利宝)",
		"HelipayUnionpayB2b"=>"银联-b2b(合利宝)",
	}

	SYSTEM_MAPPING={
		'mypost4u' => '包裹网站',
		'quaie' => 'quaie'
	}

	ORDER_TYPE_MAPPING={
		"parcel"=>"包裹",
		"package_material"=>"包材"
	}

	TURE_FALSE_MAPPING={
		true => "是",
		false => "否",
		nil => "否",
		"" => "否"
	}

	ACTUAL_PAY=%w(score e_cash)

	def status_mapping(status)
		STATUS_MAPPING[status.to_s]
	end

	def payway_paytype_mapping(payway_type)
		PAYWAY_PAYTYPE_MAPPING[payway_type]
	end

	def system_mapping(system)
		SYSTEM_MAPPING[system]
	end

	def order_type_mapping(order_type)
		ORDER_TYPE_MAPPING[order_type]
	end

	def actual_pay(payway)
		if ACTUAL_PAY.index(payway).blank?
			false
		else
			true
		end
	end

	def get_expection_type_by_auth(status)
		type=STATUS_MAPPING_TO_TYPE[status]
		if type.present? && type=='manual_payment'
			type='' unless isAuthority('10')
		elsif type.present? && type=='recall_notify'
			type='' unless isAuthority('11')
		end
		type
	end

	def true_false_mapping(field)
		TURE_FALSE_MAPPING[field]
	end
end
