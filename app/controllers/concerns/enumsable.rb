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
end