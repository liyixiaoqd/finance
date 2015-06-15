class FinanceSummary
	attr_accessor :start_time,:end_time,:total_amount,:succ_amount,:fail_amount,:total_num,:succ_num,:fail_num

	def initialize start_time,end_time,total_amount=-1,succ_amount=-1,fail_amount=-1,total_num=-1,succ_num=-1,fail_num=-1
		@start_time=start_time
		@end_time=end_time

		if(total_amount>=0)
			@total_amount = total_amount  
			@succ_amount = succ_amount  
			@fail_amount = fail_amount  
			@total_num = total_num
			@succ_num = succ_num
			@fail_num = fail_num
		else
			@total_num,@total_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,"")
			@succ_num,@succ_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,"status_succ")


			@fail_num=@total_num-@succ_num
			@fail_amount=@total_amount-@succ_amount.round(2)
		end
	end

	def setAmountAndNum!(condition)
		@total_num,@total_amount=OnlinePay.get_count_sum_by_day_condition(@start_time,@end_time,condition)
		@succ_num,@succ_amount=OnlinePay.get_count_sum_by_day_condition(@start_time,@end_time,condition+" and status like 'success%'")

		@fail_num=@total_num-@succ_num
		@fail_amount=(@total_amount-@succ_amount).round(2)
	end

	def output
		"num:#{@total_num}=#{@succ_num}+#{@fail_num}\namount:#{@total_amount}=#{@succ_amount}+#{@fail_amount}"
	end
end