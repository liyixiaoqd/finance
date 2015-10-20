require 'rails_helper'
require "support/render_views"

describe FinanceWaterController do
	fixtures :users
	fixtures :finance_waters

	let!(:set_session) do
		request.session[:admin]="admin"
		request.session[:admin_auth]=",0,1,2,3,4,5,6,7,8,9,99,"
		request.session[:admin_country]=Enumsable::COUNTRY_MAPPING_TO_DISPLAY.keys.join(",")
	end

	context "get show" do
		it "success" do
			get :show,:id=>users(:user_one),:page=>0
			expect(response.status).to eq 200
			expect(assigns(:finance_waters)).to eq FinanceWater.where(:user_id=>users(:user_one))
		end
	end

	context "get modify web" do
		it "failure html" do
			expect{
				post :modify_web,modify_web_params(999,"Sub","html","score")
			}.to change(FinanceWater,:count).by(0)
			expect(response.status).to eq 302
			expect(response.body).to redirect_to new_user_finance_water_path(users(:user_one))
			expect(flash[:notice].to_s).to match (/New amount must be greater than or equal to 0.0/)
		end

		it "success html" do
			expect{
				post :modify_web,modify_web_params(1,"Sub","html","score")
			}.to change(FinanceWater,:count).by(1)

			expect(response.status).to eq 302
			expect(response).to redirect_to show_user_finance_water_path(users(:user_one))
		end
	end

	context "get modify interface" do
		it "failure json" do
			oper=[
				{'symbol'=>"Add",'amount'=>"100",'reason'=>'score add 100','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Add",'amount'=>"50",'reason'=>'score add 50','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Sub",'amount'=>"999",'reason'=>'score sub 999','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
			].to_json
			expect{
				post :modify,modify_interface_params(oper)
			}.to change(FinanceWater,:count).by(0)

			expect(response.status).to eq 200
			# p response.body
			expect(response.body).to match (/New amount must be greater than or equal to 0.0/)
		end

		it "failure for pay json" do
			oper=[
				{'symbol'=>"Add",'amount'=>"100",'reason'=>'score add 100','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Add",'amount'=>"50",'reason'=>'score add 50','watertype'=>"score",'is_pay'=>'Y','order_no'=>''},
				{'symbol'=>"Sub",'amount'=>"119",'reason'=>'score sub 119','watertype'=>"score",'is_pay'=>'Y','order_no'=>'test_score_001'},
				{'symbol'=>"Add",'amount'=>"19",'reason'=>'e_cash add 19','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
			].to_json
			expect{
				post :modify,modify_interface_params(oper)
			}.to change(FinanceWater,:count).by(0)

			expect(response.status).to eq 200
			# p response.body
			expect(response.body).to match (/支付交易订单号不可为空/)

			oper=[
				{'symbol'=>"Add",'amount'=>"100",'reason'=>'score add 100','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Add",'amount'=>"50",'reason'=>'score add 50','watertype'=>"score",'is_pay'=>'Y','order_no'=>'33'},
				{'symbol'=>"Sub",'amount'=>"119",'reason'=>'score sub 119','watertype'=>"score",'is_pay'=>'Y','order_no'=>'test_score_001'},
				{'symbol'=>"Add",'amount'=>"19",'reason'=>'e_cash add 19','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
			].to_json
			expect{
				post :modify,modify_interface_params(oper)
			}.to change(FinanceWater,:count).by(0)

			expect(response.status).to eq 200
			# p response.body
			expect(response.body).to match (/支付交易操作符只能为减/)
		end

		it "success json" do
			old_score=users(:user_one)['score']
			old_e_cash=users(:user_one)['e_cash']
			oper=[
				{'symbol'=>"Add",'amount'=>"100",'reason'=>'score add 100','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Add",'amount'=>"50",'reason'=>'score add 50','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Sub",'amount'=>"119",'reason'=>'score sub 119','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Add",'amount'=>"19",'reason'=>'e_cash add 19','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
			].to_json
			expect{
				post :modify,modify_interface_params(oper)
			}.to change(FinanceWater,:count).by(4)

			expect(response.status).to eq 200
			# p response.body
			expect(response.body).to match (/userid.*status.*reasons.*score.*e_cash.*waterno/)
			change_user=User.find(users(:user_one))
			expect(change_user.e_cash).to eq old_e_cash+19
			expect(change_user.score).to eq old_score+100+50-119
		end

		it "success and pay json" do
			OnlinePay.where("order_no like 'test%'").each do |op|
				ReconciliationDetail.where("online_pay_id=#{op.id}").delete_all
				op.delete
			end

			old_score=users(:user_one)['score']
			old_e_cash=users(:user_one)['e_cash']
			oper=[
				{'symbol'=>"Add",'amount'=>"100",'pay_amount'=>'0','currency'=>'','reason'=>'score add 100','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Add",'amount'=>"50",'pay_amount'=>'0','currency'=>'','reason'=>'score add 50','watertype'=>"score",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Sub",'amount'=>"119",'pay_amount'=>'1.19','currency'=>'RMB','send_country'=>'nl','reason'=>'score sub 119','watertype'=>"score",'is_pay'=>'Y','order_no'=>'testQD15000000730523|QD15000000740525|QD15000001041415|QD15000001061413|QD15000001081416|QD15000001281817|QD15000001291840|QD15000001311221|QD15000001321743|QD15000000730523|QD15000000740525|QD15000001041415|QD15000001061413|QD15000001081416|QD15000001281817|QD15000001291840|QD15000001311221|QD15000001321743|QD15000000730523|QD15000000740525|QD15000001041415|QD15000001061413|QD15000001081416|QD15000001281817|QD15000001291840|QD15000001311221|QD15000001321743|QD15000001291840|QD15000001311221|QD15000001321743|'},
				{'symbol'=>"Add",'amount'=>"19",'pay_amount'=>'0','currency'=>'','reason'=>'e_cash add 19','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
				{'symbol'=>"Sub",'amount'=>"19",'pay_amount'=>'0.19','currency'=>'EUR','send_country'=>'at','reason'=>'e_cash sub 19','watertype'=>"e_cash",'is_pay'=>'Y','order_no'=>'testQD15000000730523|QD15000000740525|QD15000001041415|QD15000001061413|QD15000001081416|QD15000001281817|QD15000001291840|QD15000001311221|QD15000001321744|'},
			].to_json
			expect{
				post :modify,modify_interface_params(oper)
			}.to change(OnlinePay,:count).by(2)

			expect(response.status).to eq 200
			# p response.body
			expect(response.body).to match (/userid.*status.*reasons.*score.*e_cash.*waterno/)
			reconciliation_detail=ReconciliationDetail.unscoped.last
			expect(reconciliation_detail.online_pay.order_no).to eq "testQD15000000730523|QD15000000740525|QD15000001041415|QD15000001061413|QD15000001081416|QD15000001281817|QD15000001291840|QD15000001311221|QD15000001321744|"
			expect(reconciliation_detail.amt.to_f).to eq 0.19
			expect(reconciliation_detail.reconciliation_flag).to eq "2"
		end
	end

	context "get water_obtain" do
		it "failure call water_obtain:params_wrong" do
			water_obtain_params={
				'system'=>'mypost4u',
				'channel'=>'web',
				'userid'=>'111'
			}
			post :water_obtain,water_obtain_params

			expect(response.status).to eq 400
			expect(response.body).to match (/PARAMS WRONG/)
		end

		it "failure call water_obtain:no user" do
			water_obtain_params={
				'system'=>'mypost4u',
				'channel'=>'web',
				'userid'=>'111',
				'water_no'=>'123'
			}
			post :water_obtain,water_obtain_params

			expect(response.status).to eq 400
			expect(response.body).to match (/NO USER FIND/)
		end

		it "success call water_obtain:get all" do
			users(:user_one).finance_water.create!({
				'system'=>users(:user_one)['system'],
				'channel'=>'web',
				'userid'=>users(:user_one)['userid'],
				'symbol'=>'Add',
				'amount'=>30,
				'old_amount'=>22.2,
				'new_amount'=>52.2,
				'watertype'=>'score'
				})

			water_obtain_params={
				'system'=>'mypost4u',
				'channel'=>'web',
				'userid'=>users(:user_one)['userid'],
				'water_no'=>''
			}
			post :water_obtain,water_obtain_params

			expect(response.status).to eq 200
			expect(response.body).to match (/water/)
			res_result=JSON.parse(response.body)
			expect(res_result['water'].length).to eq 3
			expect(res_result['water'][0]['type']).to eq "e_cash"
			expect(res_result['water'][0]['amount']).to eq "11.1"
			expect(res_result['water'][1]['type']).to eq "score"
			expect(res_result['water'][1]['amount']).to eq "22.2"
			expect(res_result['water'][2]['new_amount']).to eq "52.2"
		end

		it "success call water_obtain:get waterno" do
			users(:user_one).finance_water.create!({
				'system'=>users(:user_one)['system'],
				'channel'=>'web',
				'userid'=>users(:user_one)['userid'],
				'symbol'=>'Add',
				'amount'=>30,
				'old_amount'=>22.2,
				'new_amount'=>52.2,
				'watertype'=>'score'
				})

			users(:user_one).finance_water.create!({
				'system'=>users(:user_one)['system'],
				'channel'=>'web',
				'userid'=>users(:user_one)['userid'],
				'symbol'=>'Add',
				'amount'=>1000,
				'old_amount'=>52.2,
				'new_amount'=>1052.2,
				'watertype'=>'score'
				})

			water_no=FinanceWater.unscoped().where("userid='#{users(:user_one)['userid']}'").order("id asc")[1]['id']

			water_obtain_params={
				'system'=>'mypost4u',
				'channel'=>'web',
				'userid'=>users(:user_one)['userid'],
				'water_no'=>water_no
			}
			post :water_obtain,water_obtain_params

			expect(response.status).to eq 200
			expect(response.body).to match (/water/)
			res_result=JSON.parse(response.body)
			expect(res_result['water'].length).to eq 2
			expect(res_result['water'][0]['type']).to eq "score"
			expect(res_result['water'][0]['amount']).to eq "30.0"
			expect(res_result['water'][1]['type']).to eq "score"
			expect(res_result['water'][1]['new_amount']).to eq "1052.2"
		end
	end

	context "order refund" do
		it "success call no order" do
			refund_params={
				'system'=>'mypost4u',
				'payway'=>'alipay',
				'paytype'=>'oversea',
				'order_no'=>'aaa',
				'parcel_no'=>'refund_parcel_no_1',
				'datetime'=>Time.now,
				'amount'=>10.0
			}
			post :refund,refund_params
			expect(response.status).to eq 200
			expect(response.body).to match (/success/)
		end

		it "success call" do
			op=OnlinePay.last
			refund_params={
				'system'=>op.system,
				'payway'=>op.payway,
				'paytype'=>op.paytype,
				'order_no'=>op.order_no,
				'parcel_no'=>'refunc_parcel_no_2',
				'datetime'=>Time.now,
				'amount'=>op.amount-0.01
			}
			post :refund,refund_params
			expect(response.status).to eq 200
			expect(response.body).to match (/success/)
		end
	end

	context "correct" do
		it "success correct" do
			params={
				'system' => 'mypost4u',
				'channel'  => 'spec_fixtures',
				'userid'  => users(:user_two)['userid'],
				'operator'  => 'spec_script',
				'datetime'  => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
				'oper'=>[
					{'symbol'=>"Add",'amount'=>"1000",'reason'=>'e_cash add 1000','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
					{'symbol'=>"Sub",'amount'=>"100",'reason'=>'e_cash sub 100','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''}
				].to_json
			}
			expect{
				post :modify,params
			}.to change(FinanceWater,:count).by(2)

			fw=FinanceWater.unscoped.all.order("id desc").limit(1)

			user=User.find_by_userid(users(:user_two)['userid'])
			new_e_cash=user.e_cash-(50-100)

			params={
				"system"=>"mypost4u",
				"channel"=>"web",
				"user_id"=> users(:user_two)['userid'],
				"oper"=>[
					"water_no"=>fw[0].id,
					"order_no"=>"tmp",
					"amount"=>50
					].to_json
			}

			expect{
				post :correct,params
			}.to change(FinanceWater,:count).by(1)

			user.reload
			expect(user.e_cash).to eq new_e_cash

			expect{
				post :correct,params
			}.to change(FinanceWater,:count).by(0)		

			user.reload
			expect(user.e_cash).to eq new_e_cash
		end
	end

	context "invoice_merchant" do
		it "success invoice" do
			Invoice.where("userid=?",users(:user_two)['userid']).delete_all
			params={
				'system' => 'mypost4u',
				'channel'  => 'spec_fixtures',
				'userid'  => users(:user_two)['userid'],
				'operator'  => 'spec_script',
				'datetime'  => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
				'oper'=>[
					{'symbol'=>"Add",'amount'=>"1000",'reason'=>'e_cash add 1000','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
					{'symbol'=>"Sub",'amount'=>"100",'reason'=>'e_cash sub 100','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''},
					{'symbol'=>"Sub",'amount'=>"666",'reason'=>'e_cash sub 666','watertype'=>"e_cash",'is_pay'=>'N','order_no'=>''}
				].to_json
			}
			expect{
				post :modify,params
			}.to change(FinanceWater,:count).by(3)
			
			fw_in=FinanceWater.find_by_userid_and_watertype_and_symbol_and_amount(users(:user_two)['userid'],'e_cash','Add',1000)
			fw_out_1=FinanceWater.find_by_userid_and_watertype_and_symbol_and_amount(users(:user_two)['userid'],'e_cash','Sub',100)
			fw_out_2=FinanceWater.find_by_userid_and_watertype_and_symbol_and_amount(users(:user_two)['userid'],'e_cash','Sub',666)
			params={
				"system"=>"mypost4u",
				"channel"=>"web",
				"user_id"=> users(:user_two)['userid'],
				"oper"=>[
				                {
						"invoice_no"=>"DEIN000001",
						"water_no" => [fw_in.id],
						"amount" =>fw_in.amount,
						"desc" => "充值发票",
						"operdate" =>Time.now.strftime("%Y-%m-%d"),
						"begdate" => fw_in.operdate.strftime("%Y-%m-%d"),
						"enddate" =>Time.now.strftime("%Y-%m-%d")
				                } ,
					{
						"invoice_no"=>"DEOUT00001",
						"water_no" =>[fw_out_1.id,fw_out_2.id],	
						"amount"=> (-1)*(fw_out_1.amount+fw_out_2.amount),
						"desc" => "8-1到8-15号国际运费",
						"operdate"=>Time.now.strftime("%Y-%m-%d"),
						"begdate" => fw_out_1.operdate.strftime("%Y-%m-%d"),
						"enddate" => Time.now.strftime("%Y-%m-%d")
					}
				].to_json
			}

			expect{
				post :invoice_merchant,params
			}.to change(Invoice,:count).by(2)
		end
	end

	def modify_web_params(amount,symbol,format,type)
		{
			'system' => 'mypost4u',
			'channel'  => 'spec_fixtures',
			'userid'  => users(:user_one)['userid'],
			'symbol'  => symbol,
			'amount'  => amount,
			'operator'  => 'spec_script',
			'reason'  => "rspec test:#{type}.#{symbol}  #{amount}",
			'end_time'  => Time.now.strftime("%Y-%m-%d"),
			'watertype' => type ,
			'format' => format
		}
	end

	def modify_interface_params(oper)
		{
			'system' => 'mypost4u',
			'channel'  => 'spec_fixtures',
			'userid'  => users(:user_one)['userid'],
			'operator'  => 'spec_script',
			'datetime'  => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
			'oper'=>oper
		}
	end
end