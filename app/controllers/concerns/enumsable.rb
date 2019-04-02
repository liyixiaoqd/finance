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
		"钱海"=>"oceanpayment",
		"微信"=>"wechat",
		"合利宝" => "helipay"
	}

	PAYTYPE_MAPPING_TO_DISPLAY={
		""=>"",
		"国内支付"=>"transaction",
		"海外支付"=>"oversea",
		"银联-b2c"=>"unionpay_b2c",
		"银联-b2b"=>"unionpay_b2b",
		"微信"=>"wechatpay",
		"支付宝"=>"alipay",
		"移动支付"=>"mobile_pay"
	}

	ORDER_TYPE_MAPPING_TO_DISPLAY={
		""=>"",
		"包裹"=>"parcel",
		"包材"=>"package_material"
	}
end