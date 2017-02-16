module Enumsable extend ActiveSupport::Concern
	SYSTEM_MAPPING_TO_DISPLAY={
		'mypost4u' => '包裹网站',
		'quaie' => 'quaie'
	}

	COUNTRY_MAPPING_TO_DISPLAY={
		" "=>"ALL",
		"de"=>"德国",
		"nl"=>"荷兰",
		"cn"=>"中国",
		"at"=>"奥地利",
		"gb"=>"英国"
	}

	PAYWAY_MAPPING_TO_DISPLAY={
		""=>"",
		"paypal"=>"paypal",
		"sofort"=>"sofort",
		"支付宝"=>"alipay",
		"积分"=>"score",
		"电子现金"=>"e_cash",
		"银联or微信"=>"oceanpayment"
	}

	PAYTYPE_MAPPING_TO_DISPLAY={
		""=>"",
		"国内支付"=>"transaction",
		"海外支付"=>"oversea",
		"银联-b2c"=>"unionpay_b2c",
		"银联-b2b"=>"unionpay_b2b",
		"微信"=>"wechatpay"
	}
end