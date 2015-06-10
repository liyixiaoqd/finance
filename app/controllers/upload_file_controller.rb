require 'csv'

class UploadFileController < ApplicationController
	# before_action :authenticate_admin!

	SOFORT_TRANSACTION_FILE_SPLIT=";"

	def index
	end

	def upload
		begin
			if params['file'].blank?
				flash[:notice]="选择上传文件"
			elsif params['file_type']=="sofort_transaction"
				arr=CSV.parse(params['file'].read,{:col_sep => SOFORT_TRANSACTION_FILE_SPLIT})
				message=ReconciliationSofort.new.valid_reconciliation(arr)
			elsif params['file_type']=="NL_ABN_Bank"
			elsif params['file_type']=="DE_BOC_Bank"
			else
				flash[:notice]="未定义的上传业务类型,请重新选择"
			end
		rescue=>e
			flash[:notice]="处理文件失败,请重试"
		end

		render upload_file_index_path
	end
end
