#使用表实现的SEQUENCE

class LockSequence < ActiveRecord::Base
	validates :maintype, :subtype, presence: true
	validates :seq, numericality:{:greater_than_or_equal_to=>0,only_integer: true}
	validates :status, inclusion: { in: %w(enable disable),message: "%{value} is not a valid status" }

	MAINTYPE_DESC={
		"invoice"=>{
			"GSD-"=>"德国退费发票",
			"CFN-"=>"荷兰退费发票",
			"CNG-"=>"英国退费发票",
			"GSEU-"=>"奥地利退费发票",
			"RND-"=>"德国发票",
			"FTN-"=>"荷兰发票",
			"DNG-"=>"英国发票",
			"RNEU-"=>"奥地利发票",
			"FTN-PM24"=>"荷兰包材发票",
			"RND-PM24"=>"德国包材发票",
			"GSD-PM24"=>"德国包材退费发票",
			"CFN-PM24"=>"荷兰包材退费发票",
		}
	}

	#判断交易系统来源及获取发票号
	#只有新mypost4u要产生发票号
	#rd - ReconciliationDetail record
	def self.judge_system_and_get_invoice(rd)
		if isNewMypost4uRecord?(rd)
			get_next_seq!("invoice",get_subtype("invoice",rd.send_country,rd.batch_id,rd.order_type))
		else
			""
		end
	end

	#新mypost4u交易判断逻辑
	def self.isNewMypost4uRecord?(rd)
		isflag=true

		#付款交易TM开头 ； 退费交易 20位订单号
		if ['refund_order','refund_parcel'].include? (rd.batch_id)
			if rd.batch_id=="refund_parcel"
				order_no=rd.transactionid
			else
				order_no=rd.order_no
			end

			if order_no.length==20 || order_no[0,2]=="MO"
				isflag=true
			else
				isflag=false
			end
		else
			if rd.order_no[0,2]=="TM"
				isflag=true
			else
				isflag=false
			end
		end

		isflag
	end

	def self.get_subtype(maintype,country,paytype,order_type)
		subtype=nil

		begin
			if maintype.blank?
				raise "no maintype"
			elsif maintype=="invoice"
				if country.blank?
					raise "no country for #{maintype}"
				end

				subtype=nil
				if paytype=="refund_parcel" || paytype=="refund_order"
					if order_type=="parcel"
						subtype={"de"=>"GSD-", "nl"=>"CFN-","gb"=>"CNG-", "at"=>"GSEU-"}[country.downcase]
					elsif order_type=="package_material"
						subtype={"de"=>"GSD-PM24", "nl"=>"CFN-PM24"}[country.downcase]
					end

				else
					if order_type=="parcel"
						subtype={"de"=>"RND-", "nl"=>"FTN-","gb"=>"DNG-", "at"=>"RNEU-"}[country.downcase]
					elsif order_type=="package_material"
						subtype={"de"=>"RND-PM24", "nl"=>"FTN-PM24"}[country.downcase]
					end
				end

				if subtype.blank?
					raise "type[#{maintype}] : [#{country}][#{paytype}][#{order_type}] - no subtype mapping"
				end
			end
		rescue=>e
			Rails.logger.info("get_subtype fail: #{e.message}")
			subtype=nil
		end

		subtype
	end

	#相关方法使用事物！
	def self.get_next_seq!(maintype,subtype)
		if maintype.blank? || subtype.blank?
			raise "type or subtype is nil"
		end

		ls=LockSequence.lock.find_by(maintype: maintype,subtype: subtype,status: "enable")
		if ls.blank?
			raise "LockSequence not found sequence for [#{maintype}] , [#{subtype}]"
		end
		ls.seq+=1
		ls.save!

		seq=sprintf(ls.str_format,ls.seq)
		subtype+seq
	end

	#手动运行初始化函数
	def self.manually_init_record(maintype,subtype,seq,str_format)
		begin
			if maintype.blank? || subtype.blank? || seq.blank? || str_format.blank?
				raise "maintype or subtype or seq or str_format is nil"
			end

			if LockSequence.find_by(maintype: maintype,subtype: subtype).present?
				raise "exists sequence: for [#{maintype}] , [#{subtype}]"
			end

			LockSequence.create!({
				maintype: maintype,
				subtype: subtype,
				seq: seq.to_i,
				str_format: str_format,
				status: "enable"
			})
		rescue=>e
			p e.message
			return false
		end

		true
	end
end
