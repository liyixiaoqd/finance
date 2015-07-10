class ReconciliationDetail < ActiveRecord::Base
	belongs_to :online_pay

	validates :payway, :transactionid, :transaction_status,:batch_id,:transaction_date, presence: true
	#validates :reconciliation_flag, inclusion: { in: %w{'0','1','2'},message: "%{value} is not a valid ReconciliationDetail.reconciliation_flag" }
	before_save :set_confirm!

	default_scope { order('payway,paytype asc,timestamp desc') }

	paginates_per 14

	RECONCILIATIONDETAIL_FLAG={
		'INIT' => '0',
		'FAIL' => '1',
		'SUCC' => '2',
		'NON_SYSTEM'=>'9'
	}

	RECONCILIATIONDETAIL_STATUS={
		'PAYPAL_Pending' => 'PEND',
		'PAYPAL_Processing' => 'PEND',
		'PAYPAL_Completed' => 'SUCC',
		'PAYPAL_Unclaimed' => 'SUCC',
		'PAYPAL_Denied' => 'FAIL',
		'PAYPAL_Reversed' => 'FAIL',
		'ALIPAY_TRANSACTION_succ' => 'SUCC',
		'ALIPAY_OVERSEA_P' => 'SUCC',
		'ALIPAY_OVERSEA_L' => 'SUCC',
		'ALIPAY_OVERSEA_W' => 'PEND',
		'ALIPAY_OVERSEA_F' => 'FAIL',
		'SOFORT_SUCC' => 'SUCC'
	}

	CONFIRM_FLAG={
		'INIT' => '0',
		'FAIL' => '1',
		'SUCC' => '2'
	}

	def self.init(init_params)
		find_params={}
		other_params={}

		# sofort 使用order_no作为查询条件 其他使用transactionid
		init_params.each do |k,v|
			if k=="transactionid"|| k=="payway"|| k=="paytype" || k=="order_no"
				find_params[k]=v
			else
				other_params[k]=v
			end
		end
		#Rails.logger.info("find_params:#{find_params}")
		if find_params['transactionid'].blank? && find_params['order_no'].blank?
			raise "transactionid与order_no不可都为空"
		end
		rd=ReconciliationDetail.find_or_initialize_by(find_params)
		rd.assign_attributes(other_params)
		#Rails.logger.info(rd.attributes)
		rd
		#exist_rd=ReconciliationDetail.find_by_payway_and_paytype_and_transactionid(init_params['payway'],init_params['paytype'],init_params['transactionid'])
	end

	def set_flag!(flag,desc="")
		self.reconciliation_flag=flag
		self.reconciliation_describe=desc
	end

	def valid_and_save!()
		set_params_by_transactionid!()

		if self.online_pay_id.blank?
			set_flag!(RECONCILIATIONDETAIL_FLAG['NON_SYSTEM'],"获取对应在线支付记录失败:#{self.transactionid}")
		else
			set_flag_by_status_and_amount!()
		end

		# if (self.payway=="sofort")
		# 	exist_rd=ReconciliationDetail.find_by_payway_and_paytype_and_transactionid(self.payway,self.paytype,self.transactionid)
		# 	unless exist_rd.blank?
		# 		exist_rd.delete
		# 	end
		# end
		save!()

		# exist_rd=ReconciliationDetail.find_by_payway_and_paytype_and_transactionid(self.payway,self.paytype,self.transactionid)
		# if exist_rd.blank?
		# 	save!()
		# else
		# 	Rails.logger.warn("#{self.transactionid} exist record and update status #{exist_rd.transaction_status} ==> #{self.transaction_status},flag #{exist_rd.reconciliation_flag} ==> #{self.reconciliation_flag}")
		# 	self.id=exist_rd.id
		# 	update_columns({})
		# end
		
	end

	def set_params_by_transactionid!()
		self.paytype='' if self.paytype.blank?
		self.feeamt=0.0 if self.feeamt.blank?
		self.feeamt=(-1)*self.feeamt if self.feeamt<0
		
		return nil if self.transactionid.blank? || self.payway.blank?
		# sofort 使用order_no作为查询条件 其他使用transactionid
		if self.transactionid.blank?
			self.online_pay=OnlinePay.find_by_payway_and_paytype_and_order_no(self.payway,self.paytype,self.order_no)
			if self.online_pay.blank?
				self.transactionid=self.order_no
			else
				self.transactionid=self.online_pay.reconciliation_id 
			end
		else
			self.online_pay=OnlinePay.find_by_payway_and_paytype_and_reconciliation_id(self.payway,self.paytype,self.transactionid)
		end
		
		unless self.online_pay.blank?
			self.online_pay_status=self.online_pay.status 
			self.country=self.online_pay.country
			self.send_country=self.online_pay.send_country
			self.order_no=self.online_pay.order_no
			self.system=self.online_pay.system
		end
	end

	def set_flag_by_status_and_amount!()
		if self.paytype.blank?
			reconciliation_status=RECONCILIATIONDETAIL_STATUS["#{self.payway.upcase}_#{self.transaction_status}"]
		else
			reconciliation_status=RECONCILIATIONDETAIL_STATUS["#{self.payway.upcase}_#{self.paytype.upcase}_#{self.transaction_status}"]
		end

		if reconciliation_status.blank? || self.online_pay_status.blank?
			set_flag!(RECONCILIATIONDETAIL_FLAG['FAIL'],"set_flag_by_status get status failure:#{reconciliation_status} and #{self.transaction_status} - #{self.online_pay_status}")
		else
			if reconciliation_status=="SUCC" && self.online_pay_status =~ /^success/
				if self.online_pay.rate_amount==self.amt
					set_flag!(RECONCILIATIONDETAIL_FLAG['SUCC'],"")
					#RMB交易不需要进行财务确认
				else
					set_flag!(RECONCILIATIONDETAIL_FLAG['FAIL'],"amount not match: #{self.online_pay.amount} <=> #{self.amt}")
				end
			elsif (reconciliation_status!="SUCC" && !(self.online_pay_status =~ /^success/))
				set_flag!(RECONCILIATIONDETAIL_FLAG['SUCC'],"")
			elsif (reconciliation_status=="SUCC" && ! (self.online_pay_status =~ /^success/))
				set_flag!(RECONCILIATIONDETAIL_FLAG['FAIL'],"#{self.payway} is #{reconciliation_status} but online_pay is #{self.online_pay_status}")
			elsif (reconciliation_status!="SUCC" && self.online_pay_status =~ /^success/)
				set_flag!(RECONCILIATIONDETAIL_FLAG['FAIL'],"#{self.payway} is #{reconciliation_status} but online_pay is #{self.online_pay_status}")
			else
				set_flag!(RECONCILIATIONDETAIL_FLAG['FAIL'],"unknow? #{self.payway} is #{reconciliation_status} but online_pay is #{self.online_pay_status}")
			end
		end
	end

	def set_confirm!()
		#RMB货币交易自动确认成功,且不出发票
		if self.currencycode=='RMB' && self.reconciliation_flag==RECONCILIATIONDETAIL_FLAG['SUCC']
			self.confirm_flag=CONFIRM_FLAG['SUCC']
			self.confirm_date=self.transaction_date
			self.invoice_date=self.transaction_date
		end
	end

	def warn_to_file(errmsg="unknow")
		[self.payway,self.paytype,self.transactionid,self.timestamp,self.transaction_type,self.transaction_status,self.amt,self.online_pay_id,self.online_pay_status,self.reconciliation_flag,self.reconciliation_describe,errmsg].join(",")
	end

	def self.get_confirm_summary(confirm_flag,transaction_date="")
		if transaction_date.blank?
			rd_tj=ReconciliationDetail.select("count(*) as c,sum(amt) as s,max(updated_at) as m").where("reconciliation_flag=? and confirm_flag=?",RECONCILIATIONDETAIL_FLAG['SUCC'],confirm_flag)
		else
			rd_tj=ReconciliationDetail.select("count(*) as c,sum(amt) as s,max(updated_at) as m").where("reconciliation_flag=? and confirm_flag=? and transaction_date=?",RECONCILIATIONDETAIL_FLAG['SUCC'],confirm_flag,transaction_date)
		end
		if(rd_tj[0]['s'].blank?)
			[rd_tj[0]['c'],0.00,'']
		else
			[rd_tj[0]['c'],rd_tj[0]['s'].to_f,rd_tj[0]['m']]
		end
	end
	 # def to_hash(errmsg="unknow")
		#  hash = {}; 
		#  self.attributes.each { |k,v| hash[k] = v }
		#  hash['errmsg']=errmsg

		#  hash
	 # end
end
