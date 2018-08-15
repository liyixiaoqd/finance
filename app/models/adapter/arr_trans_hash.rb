module Adapter
	class ArrTransHash
		def initialize(arr_format)
			@arr = []
			@hash = {}
			@format = arr_format   # p[]

			raise NotImplementedError.new("#{self.class.name}#initialize 是抽象方法")
		end

		# get onlinepay to hash from array
		def arr_to_hash(arr)
			if arr.length != @format.length
				raise "length not match [#{arr.length}] <-> [#{@format.length}]"
			end
			@arr = arr

			i = -1
			@format.each do |f|
				i += 1
				@arr[i].strip!
				next if f == "null"
				@hash[f] = @arr[i].strip
			end

			# spec methods
			arr_to_hash_spec()

			@hash
		end

		def arr_to_hash_spec
			raise NotImplementedError.new("#{self.class.name}#arr_to_hash_spec 是抽象方法")
		end
	end

	class ATHOnlinePaySF < ArrTransHash
		def initialize(arr_format)
			@arr = []
			@hash = {}
			@format = arr_format

			unless @format.instance_of? Array
				raise "please input array format"
			end
		end

		def arr_to_hash_spec
			@hash['user_id'] = User.find_by(system: @hash['system'], userid: @hash['userid']).id
			@hash['channel'] = 'sync_file'
			@hash['send_country'] = @hash['country']
			@hash['status'] = 'success_notify'
			@hash['rate_amount'] = @hash['amount']
			@hash['created_at'] = Time.zone.parse("#{@arr[10]} UTC")
		end
	end
end