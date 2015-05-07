class SimulationController < ApplicationController
	def index
	end

	def simulate
		userid="552b461202d0f099ec000033"
		callpath="/pay/#{userid}/submit"

		uri = URI.parse("http://127.0.0.1:3000#{callpath}")
		logger.info("path:#{callpath}")
		http = Net::HTTP.new(uri.host, uri.port)

		simulate_params={

		}

		request = Net::HTTP::Post.new(uri.request_uri) 
		#request.set_form_data(simulate_params)
		logger.info("call!!")
		response=http.request(request)
		logger.info("body:#{response.body}")

		render :text=>'end'
	end
end
