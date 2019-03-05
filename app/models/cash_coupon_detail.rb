class CashCouponDetail < ActiveRecord::Base
	validates :state, inclusion: { in: %w(use cancel frozen abnormal),message: "%{value} is not a valid state" }

	USE = "use"
	CANCEL = "cancel"
	FROZEN = "frozen"
	ABNORMAL = "abnormal"

	STEP_CANCEL_HOUR = 1

	def self.save_by_cash_coupon!(cc, quantity, order_no, state, time = Time.now)
		ccd = CashCouponDetail.new(
			cash_coupon_id: cc.id,
			quantity: quantity,
			order_no: order_no,
			state: state
		)

		if ccd.state == USE
			ccd.use_time = time
		elsif ccd.state == CANCEL
			ccd.cancel_time = time
		elsif ccd.state == FROZEN
			ccd.frozen_time = time
		end

		ccd.save!
	end

	# 根据order_no进行处理
	def self.proc_by_order_no!(order_no, state, time = Time.now)
		begin
			CashCouponDetail.where(order_no: order_no, state: FROZEN).each do |ccd|
				begin
					cc = CashCoupon.find_by(id: ccd.cash_coupon_id)
					raise "no cash_coupon record[#{ccd.cash_coupon_id}]" if cc.blank?
					cc.with_lock do 
						cc.fr_quantity_proc!(ccd.quantity, state)
					end

					ccd.state = state
					if ccd.state == USE
						ccd.use_time = time
					elsif ccd.state == CANCEL
						ccd.cancel_time = Time.now
					end
					ccd.save!
				rescue=>e
					ccd.state = ABNORMAL
					ccd.remark = e.message[0,100]
					ccd.save!
				end
			end
		rescue=>e
			Rails.logger.info("CASH_COUPONS PROC WARNING: [#{e.message}]")
		end

		true
	end

	# 定时任务, 取消1小时前的冻结数据
	def self.cron_cancel_state(step_hour = STEP_CANCEL_HOUR, time = Time.now)
		puts("CASH_COUPON_DETAILS CANCEL STATE START #{Time.now}")
		cancel_count = 0
		fail_count = 0
		CashCouponDetail.where(state: FROZEN).where("frozen_time <= '#{Time.now-STEP_CANCEL_HOUR.hour}'").each do |ccd|
			begin
				cc = CashCoupon.find_by(id: ccd.cash_coupon_id)
				raise "no cash_coupon record[#{ccd.cash_coupon_id}]" if cc.blank?
				cc.with_lock do 
					op = OnlinePay.find_by(system: cc.system, order_no: ccd.order_no)
					# 微信支付 存在暂时无对应online_pay记录情况
					if op.present? && op.is_success_self?()
						raise "对应online_pay为支付成功状态[#{op.status}]"
					else
						cc.fr_quantity_proc!(ccd.quantity, CANCEL)
					end
				end

				ccd.state = CANCEL
				ccd.cancel_time = time
				ccd.save!

				cancel_count +=1 
			rescue=>e
				ccd.state = ABNORMAL
				ccd.remark = e.message[0,100]
				ccd.save!

				fail_count += 1
			end
		end

		puts("CASH_COUPON_DETAIL cancel record [#{cancel_count} - #{fail_count}]")
		puts("CASH_COUPON_DETAILS CANCEL STATE END #{Time.now}")
	end
end