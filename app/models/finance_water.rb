class FinanceWater < ActiveRecord::Base
	include PayDetailable
	
	belongs_to :user
	validates :system, :channel, :userid, presence: true
	validates :new_amount,:old_amount, numericality:{:greater_than_or_equal_to=>0.00},if: "!self.user.isMerchant?"
	validates :amount, numericality:{:greater_than=>0.00}
	validates :symbol, inclusion: { in: %w(Add Sub),message: "%{value} is not a valid symbol" }
	validates :watertype, inclusion: { in: %w(score e_cash trading),message: "%{value} is not a valid watertype" }

	default_scope { order('watertype asc,id asc') }

	paginates_per 14

	def set_all_amount!(user_score,user_e_cash)
		if self.amount<0
			self.amount=(-1)*self.amount
			if self.symbol=="Sub"
				self.symbol="Add" 
			elsif self.symbol=="Add"
				self.symbol="Sub"
			end 
		end

		if(self.watertype=='score')
			self.old_amount=user_score
			if(self.symbol=='Add')
				self.new_amount=user_score+self.amount
			elsif(self.symbol=="Sub")
				self.new_amount=user_score-self.amount
			end
		elsif(self.watertype=='e_cash')
			self.old_amount=user_e_cash
			if(self.symbol=='Add')
				self.new_amount=user_e_cash+self.amount
			elsif(self.symbol=="Sub")
				self.new_amount=user_e_cash-self.amount
			end
		end
	end

	def set_notice_by_merchant(type)
		notice=nil

		if self.watertype=="e_cash" 
			# 超过规定天数产生待处理任务
			if type=="recharge"
				notice=Notice.set_params_by_finance_water_recharge(self)				
			end

			# 支付后余额少于0产生待处理任务
			if type=="pay"
				notice=Notice.set_params_by_finance_water_pay(self)
			end
		end

		notice
	end

	def self.save_by_online_pay(op)
		if op.system=="quaie"			
			op.user.with_lock do
				finance_water=op.user.finance_water.build()
				finance_water.system=op.system
				finance_water.channel=op.channel
				finance_water.userid=op.userid
				finance_water.operator="system_submit"
				finance_water.operdate=op.updated_at
				finance_water.symbol="Add"
				finance_water.amount=op.amount
				finance_water.watertype="e_cash"

				finance_water.reason=op.description+",id="+op.id.to_s
				finance_water.old_amount=op.user.e_cash
				finance_water.new_amount=op.user.e_cash+finance_water.amount
				finance_water.confirm_flag="1"
				op.user.update_attributes!({'e_cash'=>finance_water.new_amount})
				finance_water.save!()
				finance_water
			end
		else
			nil
		end
	end

	def self.get_tj_num(result_sql,search_sql,search_params)
		fw_tj=FinanceWater.unscoped().select("#{result_sql} as tj").where(search_sql,search_params)
		if(fw_tj[0]['tj'].blank?)
			0
		else
			fw_tj[0]['tj']
		end
	end

	def self.get_first_record(search_sql,search_params,order_sql)
		fws=FinanceWater.unscoped().where(search_sql,search_params).order(order_sql)
		if fws.blank?
			nil
		else
			fws[0]
		end
	end
end
