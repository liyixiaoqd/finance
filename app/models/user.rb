class User < ActiveRecord::Base
	has_many :finance_water
	has_many :online_pay
	validates :system, :channel, :userid, :username, presence: true
	validates :e_cash,:score,numericality:{:greater_than_or_equal_to=>0.00}
		
	before_create :create_userid_unique_valid
	#after_create :create_init_score     can't rollback !!

	default_scope { order('system asc,operdate desc') }
	paginates_per 14

	def create_init_finance(score_reason,e_cash_reason)
		begin
			if self.score>0 then 
				create_init_watertype("score",score_reason)
			end

			if self.e_cash>0 then		
				create_init_watertype("e_cash",e_cash_reason)
			end
		rescue => e
			logger.info("finance_water insert failure!! #{e.message}")
			errors.add(:base,"user finance proc failure:#{e.message}")
			return false
		end
	end

	def create_finance(watertype,reason,amount,symbol)
		finance_water_params={
			'system'=>self.system,
			'channel'=>self.channel,
			'userid'=>self.userid,
			'symbol'=>symbol,
			'operator'=>'system',
			'reason'=>reason,
			'watertype'=>watertype,
			'operdate'=>OnlinePay.current_time_format(),
			'amount'=>amount
		}

		if(watertype=="score")
			finance_water_params['old_amount']=self.score
			finance_water_params['new_amount']=self.score+amount
		elsif(watertype=="e_cash")
			finance_water_params['old_amount']=self.e_cash
			finance_water_params['new_amount']=self.e_cash+amount
		end

		self.finance_water.create!(finance_water_params)
	end

	private 
		def create_userid_unique_valid
			unless self.class.find_by_system_and_userid(self.system,self.userid).blank?
				errors.add(:base,"user has exists")
				return false
			end
		end

		def create_init_watertype(watertype,reason="init")
			finance_water_params={
				'system'=>self.system,
				'channel'=>self.channel,
				'userid'=>self.userid,
				'symbol'=>'Add',
				'old_amount'=>0.0,
				'operator'=>'system',
				'reason'=>reason,
				'operdate'=>self.operdate,
				'watertype'=>watertype
			}

			if(watertype=="score")
				finance_water_params['amount']=self.score
				finance_water_params['new_amount']=self.score
			elsif(watertype=="e_cash")
				finance_water_params['amount']=self.e_cash
				finance_water_params['new_amount']=self.e_cash
			end

			self.finance_water.create!(finance_water_params)
		end
end
