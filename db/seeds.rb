# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

BasicData.delete_all
BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"001",:sub_desc=>"postpone the date - day",
	                   :payway=>"paypal",:paytype=>"",:value=>"30")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"002",:sub_desc=>"time interval frequency - hour",
	                   :payway=>"paypal",:paytype=>"",:value=>"12")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"001",:sub_desc=>"postpone the date - day",
	                   :payway=>"alipay",:paytype=>"transaction",:value=>"30")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"002",:sub_desc=>"time interval frequency - hour",
	                   :payway=>"alipay",:paytype=>"transaction",:value=>"24")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"001",:sub_desc=>"postpone the date - day",
	                   :payway=>"alipay",:paytype=>"oversea",:value=>"30")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"002",:sub_desc=>"time interval frequency - hour",
	                   :payway=>"alipay",:paytype=>"oversea",:value=>"24")

AdminManage.delete_all
AdminManage.create!(:admin_name=>'admin',:admin_passwd=>'eb9839c141dd4df3beecb8a17e98daaf',
			:is_active=>false,:authority=>'9',:status=>'normal',
			:role=>'SuperAdmin',:last_login_time=>nil)
AdminManage.create!(:admin_name=>'finance',:admin_passwd=>'af1d6c48324c1461e12cbdefa91472f7',
			:is_active=>false,:authority=>'4',:status=>'normal',
			:role=>'Admin',:last_login_time=>nil)
AdminManage.create!(:admin_name=>'guest',:admin_passwd=>'af1d6c48324c1461e12cbdefa91472f7',
			:is_active=>false,:authority=>'0',:status=>'normal',
			:role=>'Admin',:last_login_time=>nil)

AccessAuthority.delete_all
AccessAuthority.create!(:controller=>"AdminManageController",:action=>"sign_index",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'ADMIN登入后显示界面')
AccessAuthority.create!(:controller=>"AdminManageController",:action=>"sign_in",
			:is_sign_in=>false,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'ADMIN登入界面')
AccessAuthority.create!(:controller=>"AdminManageController",:action=>"sign_out",
			:is_sign_in=>false,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'ADMIN登出界面')

AccessAuthority.create!(:controller=>"FinanceWaterController",:action=>"new",
			:is_sign_in=>true,:is_interface=>false,:access_level=>1,
			:describe=>'USER财务流水手动新增界面')
AccessAuthority.create!(:controller=>"FinanceWaterController",:action=>"show",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'USER财务流水查询显示界面')
AccessAuthority.create!(:controller=>"FinanceWaterController",:action=>"export",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'USER财务流水导出')
AccessAuthority.create!(:controller=>"FinanceWaterController",:action=>"modify",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>true,
			:describe=>'USER财务流水变更接口')
AccessAuthority.create!(:controller=>"FinanceWaterController",:action=>"modify_web",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'USER财务流水变更界面调用')

AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"alipay_oversea_return",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'alipay_oversea支付同步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"alipay_oversea_notify",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'alipay_oversea支付异步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"alipay_transaction_return",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'alipay_transaction支付同步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"alipay_transaction_notify",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'alipay_transaction支付异步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"paypal_return",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'paypal支付同步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"paypal_abort",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'paypal支付异常回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"sofort_return",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'sofort支付同步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"sofort_notify",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'sofort支付异步回调接口')
AccessAuthority.create!(:controller=>"OnlinePayCallbackController",:action=>"sofort_abort",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'sofort支付异常回调接口')

AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"show",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'支付交易查询显示界面')
AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"show_single_detail",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'单笔支付交易详细查询显示界面')
AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"index",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'交易信息查询显示界面')
AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"export",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'交易信息导出')
AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"submit",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>true,
			:describe=>'支付提交接口')
AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"submit_creditcard",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>true,
			:describe=>'支付(信用卡)提交接口')
AccessAuthority.create!(:controller=>"OnlinePayController",:action=>"get_bill_from_payment_system",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>true,
			:describe=>'获取各支付系统财务对账单接口')
AccessAuthority.create!(:controller=>"RegisteController",:action=>"index",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'USER注册查询显示界面')
AccessAuthority.create!(:controller=>"RegisteController",:action=>"show",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>true,
			:describe=>'USER详细信息查询界面')
AccessAuthority.create!(:controller=>"RegisteController",:action=>"create",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>true,
			:describe=>'USER注册接口')

AccessAuthority.create!(:controller=>"SimulationController",:action=>"index",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - 支付主界面')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"index_reconciliation",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - 对账主界面')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_reconciliation",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - 对账提交')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_finance_modify",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - 财务流水变更提交')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_registe",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - USER注册提交')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_pay",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - 支付提交')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_pay_credit",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - 支付(信用卡)提交')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"callback_return",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'模拟交易调用 - 支付同步回调')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"callback_notify",
			:is_sign_in=>false,:is_interface=>true,:is_digest_auth=>false,
			:describe=>'模拟交易调用 - 支付异步回调')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_get",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - get页面提交')
AccessAuthority.create!(:controller=>"SimulationController",:action=>"simulate_post",
			:is_sign_in=>true,:is_interface=>false,:access_level=>5,
			:describe=>'模拟交易调用 - post页面提交')

AccessAuthority.create!(:controller=>"TransactionReconciliationController",:action=>"index",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'各财务系统对账单查询显示界面')
AccessAuthority.create!(:controller=>"TransactionReconciliationController",:action=>"report",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'各财务系统对账汇总查询显示界面')

AccessAuthority.create!(:controller=>"UploadFileController",:action=>"index",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'上传文件界面')
AccessAuthority.create!(:controller=>"UploadFileController",:action=>"upload",
			:is_sign_in=>true,:is_interface=>false,:is_digest_auth=>true,
			:describe=>'上传文件处理')