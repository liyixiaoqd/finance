class OrderNoToTradeNo < ActiveRecord::Base
	before_create :create_unique_valid

	private 
		def create_unique_valid
			onttn=self.class.find_by_payway_and_paytype_and_trade_no(self.payway,self.paytype,self.trade_no)

			if onttn.blank? || onttn.order_no==self.order_no
				Rails.logger.info("OrderNoToTradeNo UNIQUE VALID :succ")
				return true
			else
				Rails.logger.info("OrderNoToTradeNo UNIQUE VALID :fail")
				errors.add(:base,"trade_no has exists")
				return false
			end
		end
end
