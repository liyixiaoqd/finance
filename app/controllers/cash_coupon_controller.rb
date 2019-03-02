class CashCouponController < ApplicationController
	include Paramsable

	protect_from_forgery :except => [:create]

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
end