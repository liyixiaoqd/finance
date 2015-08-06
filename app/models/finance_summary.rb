class FinanceSummary
	attr_accessor :start_time,:end_time,:total_amount,:succ_amount,:fail_amount,:succ_execption_amount,:uncompleted_amount,
		          :total_num,:succ_num,:fail_num,:succ_execption_num,:uncompleted_num

	def initialize start_time,end_time,total_amount=-1,isInit=true
		@start_time=start_time
		@end_time=end_time

		if isInit
			@total_num,@total_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,"")
			@succ_num,@succ_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,"status_succ")
			@fail_num,@fail_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,"status_fail")
			@succ_execption_num,@succ_execption_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,"status_succ_expection")

			@uncompleted_num=@total_num-@succ_num-@fail_num-@succ_execption_num
			@uncompleted_amount=(@total_amount-@succ_amount-@fail_amount-@succ_execption_amount).round(2)
		else
			@total_amount = 0  
			@succ_amount = 0  
			@fail_amount = 0  
			@succ_execption_amount = 0
			@uncompleted_amount = 0

			@total_num = 0
			@succ_num = 0
			@fail_num = 0
			@succ_execption_num = 0
			@uncompleted_num = 0
		end
	end

	def setAmountAndNum!(condition)
		@total_num,@total_amount=OnlinePay.get_count_sum_by_day_condition(@start_time,@end_time,condition)
		@succ_num,@succ_amount=OnlinePay.get_count_sum_by_day_condition(@start_time,@end_time,condition+" and status like 'success%'")
		@fail_num,@fail_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,condition+" and status like 'failure%' and status!='failure_notify_third'")
		@succ_execption_num,@succ_execption_amount=OnlinePay.get_count_sum_by_day_condition(start_time,end_time,condition+" and status = 'failure_notify_third'")

		@uncompleted_num=@total_num-@succ_num-@fail_num-@succ_execption_num
		@uncompleted_amount=(@total_amount-@succ_amount-@fail_amount-@succ_execption_amount).round(2)
	end

	def output
		"num:#{@total_num}=#{@succ_num}+#{@fail_num}+#{@succ_execption_num}+#{@uncompleted_num}\namount:#{@total_amount}=#{@succ_amount}+#{@fail_amount}+#{@succ_execption_amount}+#{@uncompleted_amount}"
	end
end