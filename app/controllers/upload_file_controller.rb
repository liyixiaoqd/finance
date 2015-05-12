require 'csv'

class UploadFileController < ApplicationController
	# before_action :authenticate_admin!

	SOFORT_TRANSACTION_FILE_SPLIT=";"

	def index
	end

	def upload
		begin
			if params['file_type']=="sofort_transaction"
				arr=CSV.parse(params['file'].read,{:col_sep => SOFORT_TRANSACTION_FILE_SPLIT})
				message=ReconciliationSofort.new.valid_reconciliation(arr)
			else
				raise "unknow file_type choose #{params['file_type']}"
			end
		rescue=>e
			message=e.message
		end

		render :text=>message
	end
end
