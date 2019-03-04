class CashCouponController < ApplicationController
	include Paramsable

	protect_from_forgery :except => [:create,:list,:use]

	def create
		#  params proc
        begin
            request.body.rewind
            create_params = JSON.parse request.body.read
        rescue
            create_params = params
        end

        params = create_params

		unless params_valid("cash_coupon_create",params)
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		ret_hash={
			'status'=> "failure",
			'reason' => ''
		}

		begin
			user=User.find_by_system_and_userid(params['system'],params['userid'])
			raise "#{params['userid']}无此用户" if user.blank?

			unique_flag = CashCoupon.check_unique?(params['system'], params['userid'], params['order_no'])
			raise "#{params['order_no']}已存在代金券记录,不可重复提交"if unique_flag == true


			cc = CashCoupon.new(
				system: params['system'],
				userid: params['userid'],
				order_no: params['order_no'],
				user_id: user.id,
				end_date: params['enddate'],
				quantity: params['number'].to_i,
				av_quantity: params['number'].to_i,
				fr_quantity: 0,
				cny_amount: params['cny_amount'].to_f,
				eur_amount: params['eur_amount'].to_f
			)

			cc.save
			if cc.errors.any?
				raise cc.errors.full_messages.to_s
			end

			ret_hash['status'] = 'success'
		rescue=>e
			Rails.logger.info("cash_coupon_controller create rescue: #{e.message}")
			ret_hash['reason'] = e.message
		end

		render json:ret_hash.to_json
	end

	def list
		#  params proc
        begin
            request.body.rewind
            list_params = JSON.parse request.body.read
        rescue
            list_params = params
        end

        params = list_params

		unless params_valid("cash_coupon_list",params)
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		ret_hash={
			'userid'=> params['userid'],
			'has_next' => false,
			'cash_coupons' => [],
			'reason' => ''
		}

		begin
			user=User.find_by_system_and_userid(params['system'],params['userid'])
			raise "#{params['userid']}无此用户" if user.blank?

			is_all = params['state'] == "all" ? true : false
				
			ccs, ret_hash['has_next'] = CashCoupon.list_by_user_has_next(params['system'], params['userid'], params['id'], is_all)
			ccs.each do |cc|
				ret_hash['cash_coupons'] << {
					'cny_amount' => cc.cny_amount,
					'eur_amount' => cc.eur_amount,
					'number' => cc.av_quantity,
					'frozen_number' => cc.fr_quantity,
					'all_number' => cc.quantity,
					'enddate' => cc.end_date.to_s,
					'id' => cc.id,
					'order_no' => cc.order_no
				}
			end
		rescue=>e
			Rails.logger.info("cash_coupon_controller list rescue: #{e.message}")
			ret_hash['reason'] = e.message
		end

		render json:ret_hash.to_json
	end


	def use
		#  params proc
        begin
            request.body.rewind
            use_params = JSON.parse request.body.read
        rescue
            use_params = params
        end

        params = use_params

		unless params_valid("cash_coupon_use",params)
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		ret_hash={
			'status'=> "failure",
			'reason' => ''
		}

		begin
			unless ["frozen","frozen_use","use","frozen_cancel"].include?(params['oper'])
				raise "oper[#{params['oper']}] illegal"
			end

			raise "must input 'order_no'" if params['order_no'].blank?

			user=User.find_by_system_and_userid(params['system'],params['userid'])
			raise "#{params['userid']}无此用户" if user.blank?

			if params['cash_coupons'].present? && params['cash_coupons'].class == String
				params['cash_coupons'] = JSON.parse(params['cash_coupons']) 
			end

			if ["frozen","use"].include?(params['oper']) && params['cash_coupons'].blank?
				raise "must input 'cash_coupons'"
			end

			ActiveRecord::Base.transaction do
				if ["frozen","use"].include?(params['oper'])
					params['cash_coupons'].each do |cc_info|
						cc_id, cc_quantity = cc_info.split("_")
						cc_id = cc_id.to_i
						cc_quantity = cc_quantity.to_i

						cc = CashCoupon.lock().find_by(id: cc_id, user_id: user.id, system: params['system'])
						raise "无此优惠券信息" if cc.blank?

						ccd = CashCouponDetail.find_by(cash_coupon_id: cc.id, order_no: params['order_no'], status: CashCouponDetail::FROZEN)
						raise "此订单存在对应已冻结数据,不可重复操作" if ccd.present?
						
						if params['oper'] == "frozen"
							cc.use_quantity_to_frozen!(cc_quantity, params['order_no'])
						else
							cc.use_quantity_direct!(cc_quantity, params['order_no'])
						end
					end
				else
					i = 0
					CashCouponDetail.where(order_no: params['order_no'], state: CashCouponDetail::FROZEN).each do |ccd|
						cc = CashCoupon.find_by(id: ccd.cash_coupon_id)
						next if cc.system != params['system']

						i += 1
						if params['oper'] == "frozen_use"
							cc.fr_quantity_proc!(ccd.quantity, CashCouponDetail::USE)
							ccd.state = CashCouponDetail::USE
							ccd.use_time = Time.now
						else
							cc.fr_quantity_proc!(ccd.quantity, CashCouponDetail::CANCEL)
							ccd.state = CashCouponDetail::CANCEL
							ccd.cancel_time = Time.now
						end

						ccd.remark = "interface use [#{params['oper']}]"
						ccd.save!
					end

					if i == 0 
						raise "no frozen cash_coupon can be use  for [#{params['order_no']}]"
					end
				end
			end
			ret_hash['status'] = 'success'
		rescue=>e
			Rails.logger.info("cash_coupon_controller use rescue: #{e.message}")
			ret_hash['reason'] = e.message
		end

		render json:ret_hash.to_json
	end
end