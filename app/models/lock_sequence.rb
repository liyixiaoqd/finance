#使用表实现的SEQUENCE

class LockSequence < ActiveRecord::Base
	validates :maintype, :subtype, presence: true
	validates :seq, numericality:{:greater_than=>0,only_integer: true}
	validates :status, inclusion: { in: %w(enable disable),message: "%{value} is not a valid status" }

	MAINTYPE_DESC={
		"invoice"=>{
			"D_in"=>"德国退费发票",
			"_in"=>"荷兰退费发票",
			"G_in"=>"英国退费发票",
			"AT_in"=>"奥地利退费发票",
			"GS_out"=>"德国发票",
			"C_out"=>"荷兰发票",
			"RF_out"=>"英国发票",
			"ATGS_out"=>"奥地利发票"
		}
	}

	def self.get_subtype(maintype,country,paytype)
		subtype=nil

		begin
			if maintype.blank?
				raise "no maintype"
			elsif maintype=="invoice"
				if country.blank?
					raise "no country for #{maintype}"
				end

				if paytype=="refund_parcel" || paytype=="refund_order"
					zh={"de"=>"D", "nl"=>"","gb"=>"G", "at"=>"AT"}[country.downcase]
					if zh.blank?
						raise "no country map"
					end
					subtype = zh+"_in"
				else
					zh={"de"=>"GS", "nl"=>"C","gb"=>"RF", "at"=>"ATGS"}[country.downcase]
					if zh.blank?
						raise "no country map"
					end
					subtype = zh+"_out"
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

		sprintf(ls.str_format,ls.seq)
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
