require 'nokogiri' 

class AlipayTransactionDetail
	include PayDetailable
	include AlipayDetailable
	attr_accessor :system,:amount,:description,:order_no,:logistics_name,:quantity

	#PAY_ALIPAY_TRANSACTION_PARAMS=%w{quantity amount logistics_name description order_no success_url notification_url}
	def initialize(online_pay)
		if !payparams_valid("alipay_transaction",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "alipay_transaction payparams valid failure!!"
		end

		define_var("alipay_transaction",online_pay)
	end

	def submit
		#import!!   quantity must be  integer  not  string
		options = {
			'service' => 'trade_create_by_buyer',
			'_input_charset' => 'utf-8',
			'payment_type' => '1',
			'logistics_type' => 'DIRECT',
			'logistics_fee' => '0',
			'logistics_payment' => 'SELLER_PAY',
			'partner' => Settings.alipay_transaction.pid,
			'seller_email' => Settings.alipay_transaction.seller_email,
			'description' => @logistics_name,
			'out_trade_no' => "#{@system}_#{@order_no}",
			'subject' => @description,
			'price' => @amount,
			#'price' => 0.10,
			'quantity' => @quantity.to_i,
			#'discount' => '0.00',
			'return_url' => Settings.alipay_transaction.return_url,
			'notify_url' => Settings.alipay_transaction.notify_url
		}

		redirect_url="#{Settings.alipay_transaction.alipay_transaction_api_ur}?#{query_string(options,Settings.alipay_transaction.secret)}"
		response_code=method_url_response_code("get",redirect_url,true)
		if(response_code=="200" || response_code=="302")
			["success",redirect_url,"","false",""]
		else
			Rails.logger.info(redirect_url)
			["failure","","","","get alipay url failure,code:#{response_code}"]
		end
	end

	def auto_send_good_success(trade_no)
		message="failure"
		options = {
			'service' => 'send_goods_confirm_by_platform',
			'transport_type' => 'DIRECT',
			'_input_charset' => 'utf-8',
			'partner' => Settings.alipay_transaction.pid,
			'trade_no' => trade_no,
			'logistics_name' => '寄送包裹费用'
		}

		redirect_url="#{Settings.alipay_transaction.alipay_transaction_api_ur}?#{query_string(options,Settings.alipay_transaction.secret)}"
		Rails.logger.info("AUTO SEND GOOD URL:#{redirect_url}")
		response=method_url_response("get",redirect_url,true)
		if response.code=="200" 
			doc = Nokogiri::XML(response.body.force_encoding("UTF-8"))
			if (doc.xpath("//alipay/error").text.blank? && doc.xpath("//alipay/is_success").text=="T")
				message="success"
			else
				message=doc.xpath("//alipay/error").text
			end
		else
			Rails.logger.info("AUTO SEND GOOD FAILURE:#{response.code}")
			message="AUTO SEND GOOD FAILURE:#{response.code}"
		end

		message
	end

	def submit_direct
		#import!!   quantity must be  integer  not  string
		options = {
			'service' => 'create_direct_pay_by_user',
			'_input_charset' => 'utf-8',
			'payment_type' => '1',
			'logistics_type' => 'DIRECT',
			'logistics_fee' => '0',
			'logistics_payment' => 'SELLER_PAY',
			'partner' => Settings.alipay_transaction.pid_direct,
			'seller_email' => Settings.alipay_transaction.seller_email_direct,
			'description' => @logistics_name,
			'out_trade_no' => "#{@system}_#{@order_no}",
			'subject' => @description,
			'price' => @amount,
			#'price' => 0.10,
			'quantity' => @quantity.to_i,
			#'discount' => '0.00',
			'return_url' => Settings.alipay_transaction.return_url,
			'notify_url' => Settings.alipay_transaction.notify_url
		}

		redirect_url="#{Settings.alipay_transaction.alipay_transaction_api_ur}?#{query_string(options,Settings.alipay_transaction.secret_direct)}"
		response_code=method_url_response_code("get",redirect_url,true)
		if(response_code=="200" || response_code=="302")
			["success",redirect_url,"","false",""]
		else
			Rails.logger.info(redirect_url)
			["failure","","","","get alipay url failure,code:#{response_code}"]
		end
	end

	private 
		def spec_payparams_valid(online_pay)
			errmsg=''
			if(online_pay['quantity']!=1)
				errmsg="alipay_transaction.quantity must be 1"
				Rails.logger.info(errmsg)
			end

			if errmsg.blank?
				true
			else
				false
			end
		end
end