desc "财务对账rake任务 - 自动调用相关支付系统获取交易信息"

namespace :finance do
	desc "对账总调度"
	task :reconciliation,[:arg1,:arg2] do|t,args|
		@interface_logger = Logger.new("log/reconciliation.log")
		@interface_logger.level=Logger::INFO
		@interface_logger.datetime_format="%Y-%m-%d %H:%M:%S"
		@interface_logger.formatter=proc{|severity,datetime,progname,msg|
			"[#{datetime}] :#{msg}\n"
		}

		@beg = args[:arg1]
		@end = args[:arg2]

		@interface_logger.info("=================== reconciliation start:#{@beg} -- #{@end}===================")
		Rake::Task["finance:reconciliation_alipay_oversea"].invoke
		@interface_logger.info("---------------------------------")
		Rake::Task["finance:reconciliation_alipay_transaction"].invoke
		@interface_logger.info("---------------------------------")
		Rake::Task["finance:reconciliation_paypal"].invoke
		@interface_logger.info("---------------------------------")
		Rake::Task["finance:reconciliation_oceanpayment"].invoke
		@interface_logger.info("---------------------------------")
		@interface_logger.info("=================== reconciliation end:#{@beg} -- #{@end}===================\n\n\n\n")
	end

	desc "对账:支付宝-海外"
	task :reconciliation_alipay_oversea =>[:environment] do 
		@interface_logger.info("reconciliation_alipay_oversea start")
		reconciliation=ReconciliationAlipayOversea.new("forex_compare_file")
		message=reconciliation.finance_reconciliation()
		#message.split('</br>').each do |t| @interface_logger.info t end
		@interface_logger.info(out_message(message))
		@interface_logger.info("reconciliation_alipay_oversea end")
	end

	desc "对账:支付宝-国内"
	task :reconciliation_alipay_transaction=>[:environment] do
		#不使用新国内支付宝帐号
		@interface_logger.info("reconciliation_alipay_transaction new account start")
		reconciliation=ReconciliationAlipayTransaction.new("account.page.query",Settings.alipay_transaction.seller_email_direct)
		message=reconciliation.finance_reconciliation()
		#message.split('</br>').each do |t| @interface_logger.info t end
		@interface_logger.info(out_message(message))
		@interface_logger.info("reconciliation_alipay_transaction new account end")

		######## TMP ########
		@interface_logger.info("reconciliation_alipay_transaction old account start")
		reconciliation=ReconciliationAlipayTransaction.new("account.page.query",Settings.alipay_transaction.seller_email)
		message=reconciliation.finance_reconciliation()
		#message.split('</br>').each do |t| @interface_logger.info t end
		@interface_logger.info(out_message(message))
		@interface_logger.info("reconciliation_alipay_transaction old account end")
	end

	desc "对账:paypal"
	task :reconciliation_paypal=>[:environment] do
		@interface_logger.info("reconciliation_paypal start")
		country_arr=%w(de at nl gb de_pm nl_pm)
		country_arr.each do |country|
			@interface_logger.info("country #{country} start")
			reconciliation=ReconciliationPaypal.new("TransactionSearch",country)
			message=reconciliation.finance_reconciliation()
			#message.split('</br>').each do |t| @interface_logger.info t end
			@interface_logger.info(out_message(message))
			@interface_logger.info("country #{country} end")
		end
		@interface_logger.info("reconciliation_paypal end")
	end

	desc "对账:sofort - 此支付方式手动上传文件核对,不做使用"
	task :reconciliation_sofort=>[:environment] do
	end

	desc "对账:oceanpayment - 包含银联b2b+银联b2c+微信"
	task :reconciliation_oceanpayment=>[:environment] do
		if @interface_logger.blank?
			@interface_logger = Logger.new("log/reconciliation.log")
		end
		@interface_logger.info("reconciliation_oceanpayment start")
		["unionpay_b2c", "unionpay_b2b", "wechatpay"].each do |subtype|
			@interface_logger.info("mypost4u #{subtype} start")
			reconciliation=ReconciliationOceanpayment.new(subtype,"mypost4u")
			message=reconciliation.finance_reconciliation()
			@interface_logger.info(out_message(message))
			@interface_logger.info("mypost4u #{subtype} end [#{message}]")
		end
		["unionpay_b2c", "wechatpay", "alipay"].each do |subtype|
			@interface_logger.info("quaie #{subtype} start")
			reconciliation=ReconciliationOceanpayment.new(subtype,"quaie")
			message=reconciliation.finance_reconciliation()
			@interface_logger.info(out_message(message))
			@interface_logger.info("quaie #{subtype} end")
		end
		@interface_logger.info("reconciliation_oceanpayment end")
	end

	def out_message(message)
		out=""
		pre="\t\t"
		message.split('</br>').each do |t| out=out+"\n"+pre+t end
		out
	end
end

