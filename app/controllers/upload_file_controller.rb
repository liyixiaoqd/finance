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
				reconciliation=ReconciliationSofort.new()
				flash[:notice],flash[:error]=reconciliation.valid_reconciliation(arr)
			elsif params['file_type']=="NL_ABN_Bank"
				filename=write_file(params['file'],"xls")
				reconciliation=ReconciliationSofort.new()
				flash[:notice],flash[:error]=reconciliation.valid_reconciliation_by_country("nl",filename)

				File.delete(filename)
			elsif params['file_type']=="DE_BOC_Bank"
				filename=write_file(params['file'],"xlsx")
				reconciliation=ReconciliationSofort.new()
				flash[:notice],flash[:error]=reconciliation.valid_reconciliation_by_country("de",filename)

				File.delete(filename)
			elsif params['file_type']=="AT_STA_Bank"
				filename=write_file(params['file'],"xlsx")
				reconciliation=ReconciliationSofort.new()
				flash[:notice],flash[:error]=reconciliation.valid_reconciliation_by_country("at",filename)
				File.delete(filename)
			else	
				flash[:notice]="未定义的上传业务类型,请重新选择"
			end
		rescue=>e
			logger.info(e.message)
			flash[:notice],flash[:error]="处理文件失败,请重试",e.message
			File.delete(filename) if File.exists?(filename)
		end

		render upload_file_index_path
	end

	private 
		def write_file(param_file,extension)
			time_version=OnlinePay.current_time_format("%Y%m%d%H%M%S")
			filename=Rails.root.join("upload_file","#{param_file.original_filename}_#{time_version}.#{extension}")
			File.open(filename, "wb") { |f| f.write(param_file.read) }

			filename
		end
end
