desc "对接相关系统-init"

namespace :init do
	desc "清理所有数据"
	task :clean_data => [:environment] do
		ReconciliationDetail.delete_all
		OnlinePay.delete_all
		FinanceWater.delete_all
		User.delete_all
	end

	desc "初始化用户"
	task :init_user,[:filename] =>[:environment] do|t,args|
		p "init_user start! filename:[#{args[:filename]}]"
		# 分隔符使用 |&|
		# 字段如下:
		# system  userid  username  email  accountInitAmount  accountInitReason  scoreInitAmount  scoreInitReason
		unless File.exist?(args[:filename])
			p "file not exist!!"
			next
		end

		wrongnum=0
		succnum=0
		allnum=0
		File.open(args[:filename],"r") do |file|
			file.each_line{|line|
				allnum+=1

				user_arr=line.split("|&|")
				begin
					ActiveRecord::Base.transaction do
						user=User.new()
						user.system=user_arr[0]
						user.channel="init_user"
						user.userid=user_arr[1]
						user.username=user_arr[2]
						user.email=user_arr[3]
						user.e_cash=user_arr[4]
						user.score=user_arr[6]
						user.operator="system"
						user.operdate=OnlinePay.current_time_format()

						user.save && user.create_init_finance(user_arr[7],user_arr[5])
						
						if user.errors.any?
							p "#{user.username} create failure: #{user.errors.full_messages.join(',')}"
							wrongnum+=1
							raise "wrong"
						else
							succnum+=1
						end
					end		
				rescue=>e
					if e.message!="wrong"
						p "#{allnum} execption:#{e.message}"
					end
				end
			}
			p "allnum:#{allnum} = succnum:#{succnum} + wrongnum:#{wrongnum}"
		end

		p "init_user success end!"
	end
end