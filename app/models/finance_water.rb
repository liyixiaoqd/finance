class FinanceWater < ActiveRecord::Base
	belongs_to :user
	validates :system, :channel, :userid, presence: true
	validates :amount,:new_amount,:old_amount, numericality:{:greater_than_or_equal_to=>0.00}
	validates :symbol, inclusion: { in: %w(Add Sub),message: "%{value} is not a valid symbol" }
	validates :watertype, inclusion: { in: %w(score e_cash trading),message: "%{value} is not a valid watertype" }
end
