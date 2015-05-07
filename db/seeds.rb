# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

BasicData.delete_all
BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"001",:sub_desc=>"postpone the date - day",
	                   :payway=>"paypal",:paytype=>"",:value=>"30")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"002",:sub_desc=>"time interval frequency - hour",
	                   :payway=>"paypal",:paytype=>"",:value=>"12")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"001",:sub_desc=>"postpone the date - day",
	                   :payway=>"alipay",:paytype=>"transaction",:value=>"30")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"002",:sub_desc=>"time interval frequency - hour",
	                   :payway=>"alipay",:paytype=>"transaction",:value=>"24")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"001",:sub_desc=>"postpone the date - day",
	                   :payway=>"alipay",:paytype=>"oversea",:value=>"30")

BasicData.create!(:basic_type=>"00A",:desc=>"financial reconciliation interface configuration",
	                   :basic_sub_type=>"002",:sub_desc=>"time interval frequency - hour",
	                   :payway=>"alipay",:paytype=>"oversea",:value=>"24")