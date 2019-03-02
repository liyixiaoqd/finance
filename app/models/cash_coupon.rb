class CashCoupon < ActiveRecord::Base
	validates :cny_amount,:eur_amount, numericality:{:greater_than_or_equal_to=>0.00}
	validates :quantity,:av_quantity,:fr_quantity, numericality:{:greater_than_or_equal_to=>0}

	PRE_LIMIT_NUM = 30	# 每次查询时,最多返回多少笔

	# is unique ,
	# ture 表示存在重复
	def self.check_unique?(system, userid, order_no)
		CashCoupon.find_by(system: system, userid: userid, order_no: order_no).present?
	end

	# is_all 是否查询所有记录(包含无可用数量的)
	def self.list_by_user(system, userid, id = nil, is_all = false, limit_num = PRE_LIMIT_NUM)
		ccs = CashCoupon.where(system: system, userid: userid).limit(limit_num).order("id asc")
		
		if id.present?
			ccs = ccs.where("id > #{id}")
		end

		if is_all == false
			ccs = ccs.where("av_quantity>0 or fr_quantity>0").where("end_date > '#{Time.now.beginning_of_day}'")
		end

		ccs
	end

	def self.list_by_user_has_next(system, userid, id =nil , is_all = false, limit_num = PRE_LIMIT_NUM)
		ccs = list_by_user(system, userid, id, is_all , limit_num+1)

		next_flag = false
		# 存在数据 且长度相同, 删除最后一条多余数据
		if ccs.present? && ccs.length == limit_num+1
			next_flag = true
			ccs.delete(ccs.length)
		end

		[ccs, next_flag]
	end

	# 使用代金券 - 冻结状态
	def use_quantity_to_frozen!(use_quantity, order_no)
		raise "优惠券可用数量不足,剩余可用[#{av_quantity}]张" if av_quantity < use_quantity

		Rails.logger.info("CASH_COUPONS[#{id}] USE QUANTITY TO FROZEN START: av[#{av_quantity}], fr[#{fr_quantity}] - [#{use_quantity}]")

		self.av_quantity = self.av_quantity - use_quantity
		self.fr_quantity = self.fr_quantity + use_quantity

		begin
			CashCouponDetail.save_by_cash_coupon!(self, use_quantity, order_no, CashCouponDetail::FROZEN)
		rescue=>e
			Rails.logger.info("cash_coupon_detail save failure: #{e.message}")
			raise "代金券明细处理异常"
		end

		save
		if self.errors.any?
			Rails.logger.info("cash_couopns save failure: #{self.errors.full_messages.to_s}")
			raise "代金券处理异常"
		end

		Rails.logger.info("CASH_COUPONS[#{id}] USE QUANTITY TO FROZEN END: av[#{av_quantity}], fr[#{fr_quantity}] - [#{use_quantity}]")
	end

	# 使用代金券 - 直接使用
	# 产生使用的明细记录
	# 上层调用需要使用事物 且 Lock本记录 !!
	def use_quantity_direct!(use_quantity, order_no)
		raise "优惠券可用数量不足,剩余可用[#{av_quantity}]张" if av_quantity < use_quantity

		Rails.logger.info("CASH_COUPONS[#{id}] USE QUANTITY DIRECT START: av[#{av_quantity}] - [#{use_quantity}]")

		self.av_quantity = self.av_quantity - use_quantity

		begin
			CashCouponDetail.save_by_cash_coupon!(self, use_quantity, order_no, CashCouponDetail::USE)
		rescue=>e
			Rails.logger.info("cash_coupon_detail save failure: #{e.message}")
			raise "代金券明细处理异常"
		end

		save
		if self.errors.any?
			Rails.logger.info("cash_couopns save failure: #{self.errors.full_messages.to_s}")
			raise "代金券处理异常"
		end

		Rails.logger.info("CASH_COUPONS[#{id}] USE QUANTITY DIRECT END: av[#{av_quantity}] - [#{use_quantity}]")
	end

	# 冻结数据处理
	def fr_quantity_proc!(quantity, state)
		Rails.logger.info("CASH_COUPONS[#{id}] PROC FR_QUANTITY START: [#{state}] av[#{av_quantity}], fr[#{fr_quantity}] - [#{quantity}]")

		if state == CashCouponDetail::USE
			self.fr_quantity = self.fr_quantity - quantity
		elsif state == CashCouponDetail::CANCEL
			self.fr_quantity = self.fr_quantity - quantity
			self.av_quantity = self.av_quantity + quantity
		end

		save
		if self.errors.any?
			Rails.logger.info("cash_couopns save failure: #{self.errors.full_messages.to_s}")
			raise "代金券处理异常"
		end	

		Rails.logger.info("CASH_COUPONS[#{id}] PROC FR_QUANTITY END: [#{state}] av[#{av_quantity}], fr[#{fr_quantity}] - [#{quantity}]")
	end
end