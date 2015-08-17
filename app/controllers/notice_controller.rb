class NoticeController < ApplicationController
	def index
		flag=params[:flag] unless params[:flag].blank?

		if flag.blank?
			@notices=Notice.all.page(params[:page])
		else
			@notices=Notice.where("flag=?",flag).page(params[:page])
		end
		@flag=flag
	end

	def handle
		notice=Notice.find(params[:notice_id])
		unless notice.blank?
			begin
				notice.update_attributes!(
					{
						'flag'=>'1',
						'proc_user'=>session['admin'],
						'proc_time'=>Time.now
					}
				) 
				flash[:notice]="处理成功"
			rescue=>e
				flash[:notice]="处理异常:#{e.message}"
			end
		else
			flash[:notice]="获取通知记录出错,请确认"
		end
		redirect_to notice_index_path(:flag=>'0')
	end
end
