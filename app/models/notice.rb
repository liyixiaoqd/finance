class Notice < ActiveRecord::Base
	belongs_to :finance_water

	NOTICE_NOTICE_TYPE_ENUM=%w{pay recharge}

	validates :notice_type, inclusion: { in: NOTICE_NOTICE_TYPE_ENUM,message: "%{value} is not a valid notice.notice_type" }

	default_scope { order('opertime asc,created_at asc') }

	paginates_per 20

	def self.set_params_by_finance_water_pay(fw)
		notice=nil
		if fw.new_amount<0
			if Notice.find_by_finance_water_id_and_flag_and_notice_type(fw.id,'0','pay').blank?
				notice=Notice.new
				notice.finance_water_id=fw.id
				notice.title="支付警告:电商[#{fw.user.username}] - 电子现金余额小于0,[#{fw.new_amount}]"
				notice.content=notice.title
				notice.flag="0"
				notice.notice_type="pay"
				notice.opertime=fw.created_at
			else
				Rails.logger.info("#{fw.id} 已存在未处理任务记录")
			end
		end
		notice
	end

	def self.set_params_by_finance_water_recharge(fw)
		notice
		if fw.confirm_flag=='0'
			if Notice.find_by_finance_water_id_and_flag_and_notice_type(fw.id,'0','recharge').blank?
				notice=Notice.new
				notice.finance_water_id=fw.id
				notice.title="充值警告:电商[#{fw.user.username}] - 充值记录尚未上传证明,[#{fw.amount}]"
				notice.content=notice.title
				notice.flag="0"
				notice.notice_type="recharge"
				notice.opertime=fw.created_at
			else
				Rails.logger.info("#{fw.id} 已存在未处理任务记录")
			end
		end
		notice
	end

	def self.get_details_by_num(num)
		Notice.where("flag='0'").limit(num)
	end

	def self.get_all_num
		n_tj=Notice.select('count(*) as c').where("flag='0'")

		if n_tj[0]['c'].blank?
			0
		else
			n_tj[0]['c']
		end
	end
end
