class RegisteController < ApplicationController
	protect_from_forgery :except => :create

	include Paramsable

	before_action :authenticate_admin!,:only=>:index

	def index
		@users=User.all
	end

	def create
		#valid input params
		render json:{},status:400 and return unless params_valid("registe_create",params)

		ret_hash={
			'system'=>params['system'],
			'channel'=>params['channel'],
			'userid'=>params['userid'],
			'status'=>'failure',
			'reasons'=>[]
		}
		
		begin
			ActiveRecord::Base.transaction do
				user=new_user_params(params)
				user.save && user.create_init_finance
				if user.errors.any?
					user.errors.full_messages.each do |msg|
						ret_hash['reasons']<<{'reason'=>msg}
					end
					raise "create use failure"
				else
					ret_hash['status']='success'
				end
			end
		rescue=>e
			logger.info("create use failure! #{e.message}")
			ret_hash['reasons']<<e.message
		end

		render json:ret_hash.to_json 
	end
	
	private
		def get_test_user
			user=User.new()
			user.system="mypost4u"
			user.channel="web"
			user.userid="552b461202d0f099ec000002"
			user.username="testname"
			user.email="testname@126.com"
			user.e_cash=5.0
			user.score=11.0
			user.operator="system"
			user.operdate="2015-04-22 09:00:00"		
		
			user
		end

		def new_user_params(params)
			user=User.new()
			user.system=params["system"]
			user.channel=params["channel"]
			user.userid=params["userid"]
			user.username=params["username"]
			user.email=params["email"]
			user.e_cash=params["accountInitAmount"]
			user.score=params["scoreInitAmount"]
			user.operator=params["operator"]
			user.operdate=params["datetime"]
		
			user
		end
end
