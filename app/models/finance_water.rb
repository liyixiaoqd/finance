class FinanceWater < ActiveRecord::Base
	belongs_to :user
	validates :system, :channel, :userid, presence: true
	validates :new_amount,:old_amount, numericality:{:greater_than_or_equal_to=>0.00}
	validates :amount, numericality:{:greater_than=>0.00}
	validates :symbol, inclusion: { in: %w(Add Sub),message: "%{value} is not a valid symbol" }
	validates :watertype, inclusion: { in: %w(score e_cash trading),message: "%{value} is not a valid watertype" }

	default_scope { order('watertype asc,id asc') }

	paginates_per 14

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

				finance_water.reason=op.description+",id="+op.id
				finance_water.old_amount=op.user.e_cash
				finance_water.new_amount=op.user.e_cash+finance_water.amount
				op.user.update_attributes!({'e_cash'=>finance_water.new_amount})
				finance_water.save!()
				finance_water
			end
		else
			nil
		end
	end
end
