class ThirdPartyServiceController < ApplicationController
	protect_from_forgery :except => [:exchange_rate]

	include Paramsable

	def exchange_rate
		begin
			request.body.rewind
			use_params=JSON.parse request.body.read
		rescue=>e
			use_params=params
		end
		
		unless params_valid("exchange_rate",use_params)
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		if use_params['currencys'].blank? || use_params['currencys'].class.to_s!="Array" || use_params['rate_date'].blank?
			render json:{'SYSTEM'=>'PARAMS WRONG!'},status:400 and return 
		end

		ret_info=[]

		use_params['currencys'].each do |currency|
			begin
				er=ExchangeRate.find_by(currency: currency,rate_date: use_params['rate_date'])
				if er.blank? || er.isGetSuccess?() == false
					raise "exchange rate not get and pleasn retry-after"
				end

				ret_info<<{
					currency: currency,
					rate: er.rate,
					rate_datetime: er.rate_datetime,
					status: 'succ',
					reason: nil
				}
			rescue=>e
				ret_info<<{
					currency: currency,
					rate: 0.0000,
					rate_datetime: nil,
					status: 'fail',
					reason: e.message
				}
			end
		end


		render json:ret_info.to_json
	end
end