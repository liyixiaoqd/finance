class ExchangeRate < ActiveRecord::Base
	include PayDetailable

	validates :currency, :rate_date, :flag, presence: true
	#validates :currency,:rate_date, uniqueness: true

	validates :rate, numericality: { :greater_than_or_equal_to=>0.0000 }
	validates :flag, numericality: { only_integer: true,:greater_than_or_equal_to=>0,:less_than_or_equal_to=>9 }
	#flag  0:初始化尚未获取汇率 , 1:获取失败 , 8:获取成功,但浮动较大(%5) , 9:获取成功

	EXCHANGE_RATE_WEB_URL="http://srh.bankofchina.com/search/whpj/search.jsp"

	CURRENCY_WEB_MAPPING={
		"GBP"=>"1314",
		"EUR"=>"1326"
	}

	def self.checkIsNormal(get_date=Time.now.strftime("%Y-%m-%d"))
		normal_flag=false
		msg=""
		currency_info=[]
		currency_array=["GBP","EUR"]
		
		currency_array.each do |currency|
			begin
				er=ExchangeRate.find_by(currency: currency,rate_date: get_date)
				if er.blank?
					currency_info<<{currency=>"0.0"}
					raise "#{get_date},#{currency} need check, no record"
				end
				
				currency_info<<{currency=>er.rate.to_s}
				if er.isGetSuccess?()==false || er.flag!=9
					raise "#{get_date},#{currency} need check,flag[#{er.flag}],[#{er.remark}]"
				end

				normal_flag=true
			rescue=>e
				Rails.logger.info("checkIsNormal rescue:#{e.message}")
				msg+=e.message+";"
			end
		end

		normal_flag=false if msg.present?

		[normal_flag,currency_info,msg]
	end

	#由于要获取每天9点后的最近一条数据,因此crontab需要配置从9点开始到11点结束，每5分钟执行
	#*/5 9-11 * * * /bin/bash -l -c 'source ~/.bashrc && source ~/.bash_profile && cd /opt/rails-app/finance && rails runner -e test 'ExchangeRate.getExchangeRate' >> /opt/rails-app/finance/log/cron_get_exchange_rate.log 2>&1'
	def self.getExchangeRate(get_date=Time.now.strftime("%Y-%m-%d"))
		currency_array=["GBP","EUR"]

		currency_array.each do |currency|
			begin
				er=ExchangeRate.find_by(currency: currency,rate_date: get_date)
				if er.blank?
					er=ExchangeRate.new(currency: currency,rate_date: get_date)
				elsif er.present? && er.isGetSuccess?()
					puts("[#{get_date}],[#{currency}] already obtain : [#{er.rate}],[#{er.rate_datetime}]")
					next
				end

				rate_info={}
				rate_info=getCurrencyRateFromWeb(currency,get_date)

				er.rate=rate_info['rate']
				er.rate_datetime=rate_info['rate_datetime']
				er.remark=rate_info['msg']

				er.setFlag!
				er.save!
			rescue=>e
				puts("[#{get_date}],[#{currency}] obtain rescue: [#{e.message}]")
			end
		end
	end

	def self.getCurrencyRateFromWeb(currency,get_date)
		rate_info={
			"rate"=>0.0000,
			"rate_datetime"=>nil,
			"msg"=>nil
		}

		begin
			post_params={
				"erectDate"=>get_date,
				"pjname"=>CURRENCY_WEB_MAPPING[currency]
			}
			if post_params['pjname'].blank?
				raise "no mapping to [#{currency}] in ExchangeRate::CURRENCY_WEB_MAPPING"
			end
			tmp_er=ExchangeRate.new
			response=tmp_er.method_url_response("post",EXCHANGE_RATE_WEB_URL,false,post_params)
			#puts("[#{response.code}] , [#{response.body}]")
			if response.code!="200"
				raise "get web info failure[#{response.code}]"
			end

			body_result_info=/(BOC_main publish.*?<\/table>)/m.match(response.body) 
			if body_result_info.blank?
				raise "no currency info get"
			end
			table_content=body_result_info[1]
			table_num=tmp_er.get_table_tr_num(table_content)
			if table_num<=1
				raise "table info get failure:[#{table_content}]"
			end

			# for i in 0...8
			# 	if tmp_er.get_content_from_table(table_content,0,i)=="现汇卖出价"
			# 		value_index=i
			# 	elsif tmp_er.get_content_from_table(table_content,0,i)=="发布时间"
			# 		time_index=i
			# 	end

			# 	if time_index>=0 && value_index>=0
			# 		break
			# 	end
			# end

			#获取超过9点的第一条
			value_index,time_index=3,7	#现汇卖出价,发布时间
			value,time=-1,nil
			threshold_time="#{get_date.gsub("-",".")} 09:00:00"

			get_num=0
			for i in 1...table_num
				tmp_time=tmp_er.get_content_from_table(table_content,i,time_index)
				if tmp_time.blank? || threshold_time>tmp_time 
					break
				end
				get_num+=1

				time=Time.parse(tmp_time).in_time_zone("Beijing").utc
				#puts("value:[#{value}],tmp_time:[#{tmp_time}]==>time:[#{time}]")
				value=tmp_er.get_content_from_table(table_content,i,value_index).to_f
			end
			if get_num==0
				raise "no info get < [#{threshold_time}] , table_num:[#{table_num}]"
			end

			if time.blank? || value.blank? || value<0.0000
				raise "get value,time into failure: [#{table_content}],[#{table_num}]"
			end

			rate_info['rate']=(value/100*1.015).round(4)
			rate_info['rate_datetime']=time

			puts("value:[#{value}],rate:[#{rate_info['rate']}],time:[#{time}]")
		rescue=>e
			puts("getCurrencyRateFromWeb obtain rescue: #{e.message}")
			Rails.logger.info(e.backtrace.inspect) unless Rails.env.production?
			rate_info['rate']=0.0000
			rate_info['msg']=e.message[0,100]
		end

		rate_info
	end

	def isGetSuccess?
		if flag==0 || flag==1 || rate<0.0001
			false
		else
			true
		end
	end

	def setFlag!
		self.flag=1

		if self.rate<0.0001
			self.flag=1
		else
			#获取前一天汇率,判断是否汇率异常
			begin
				pre_date=(self.rate_date-1.day).strftime("%Y-%m-%d")
				pre_er=ExchangeRate.find_by(currency: self.currency,rate_date: pre_date)
				if pre_er.blank?
					#第一次获取
					if ExchangeRate.where(currency: self.currency).count<1
						self.flag=8
					else
						raise "no record?"
					end
				elsif pre_er.isGetSuccess? == false
					raise "record obtain failure? [#{pre_er.remark}]"
				else
					#是否浮动超过5%
					if pre_er.rate*0.95 > self.rate || pre_er.rate*1.05 < self.rate
						puts("[#{self.rate_date}] get pre day's rate threshold: [#{pre_er.rate}] <=> [#{self.rate}]")
						self.remark="[#{self.rate_date}] get pre day's rate threshold: [#{pre_er.rate}] <=> [#{self.rate}]"
						self.flag=8
					else
						self.flag=9
					end
				end
			rescue=>e
				puts("[#{self.rate_date}] get pre day's rate rescue: #{e.message}")
				self.remark=e.message
				self.flag=8
			end
		end


		self.flag=flag
	end


end
