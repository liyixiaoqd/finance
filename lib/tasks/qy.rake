desc "导入用户ID新旧对应关系"

#run : rake import:qy_id_matchs RAILS_ENV=production
namespace :import do
        desc "import_qy_id_matchs"
        task :qy_id_matchs=> [:environment] do
        	separator="|&|"
        	log_file=File.open("lib/tasks/import_qy_id_matchs_log.txt","w")
        	reload_file=File.open("lib/tasks/import_qy_id_matchs_reload.txt","w")
        	log_file.puts "import qy_id_matchs start : #{Time.now}"
        	line_index=0
        	reload_num=0
        	File.open("lib/tasks/export_qy_id_matchs.txt","r") do |file|
        		while line=file.gets
        			line_index+=1
        			field_array=line.chomp.split(separator)
        			begin
                                                    if QyIdMatch.find_by(old_id: field_array[0],old_table: field_array[1]).present?
                                                        raise "has exists!"
                                                    end
	        			QyIdMatch.create!({
					old_id: field_array[0],
					old_table: field_array[1],
					new_id: field_array[2],
					new_table: field_array[3],
	        			})
	        			log_file.puts "succ : #{line_index}"
	        		rescue=>e
	        			log_file.puts "fail : #{line_index} : #{field_array[0]} : #{e.message}"
	        			reload_num+=1
        				reload_file.puts line
	        		end
        		end
        	end

        	log_file.puts "import qy_id_matchs end : #{Time.now} , succ: #{line_index-reload_num} , fail: #{reload_num}"
        	log_file.close

        	reload_file.close
        	if reload_num==0
        		File.delete(reload_file)
        	end
        end

        desc "update_users_by_qy"
        task :update_users_by_qy=> [:environment] do
        	log_file=File.open("lib/tasks/import_qy_update_users.txt","w")
        	QyIdMatch.where(old_table: "users").each do |qim|
	       ActiveRecord::Base.transaction do
        		begin
	        		user=User.find_by(system: "mypost4u",userid: qim.old_id)
	        		if user.blank?
	        			raise "no use[#{qim.old_id}] get"
	        		end

	        		user.update_attributes!({userid: qim.new_id})
                                       user.online_pay.update_all({userid: qim.new_id})
                                       user.finance_water.update_all({userid: qim.new_id})
                                       
	        		log_file.puts "succ : #{qim.old_id}"
	        	rescue=>e
	        		log_file.puts "fail : #{qim.old_id} : #{e.message}"
	        	end
                    end
        	end
        end
end