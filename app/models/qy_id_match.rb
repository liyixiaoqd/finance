class QyIdMatch < ActiveRecord::Base
	validates :old_id,:old_table,:new_id,:new_table, presence: true
end