require 'rails_helper'
require "support/render_views"

describe FinanceWaterController do
	fixtures :users
	fixtures :finance_waters

	let!(:set_session) do
		request.session[:admin]="admin"
	end

	context "get show" do
		it "success" do
			get :show,:id=>users(:user_one),:page=>0
			expect(response.status).to eq 200
			expect(assigns(:finance_waters)).to eq FinanceWater.where(:user_id=>users(:user_one))
		end
	end

	context "get modify" do
		it "failure json" do
			expect{
				post :modify,modify_params(999,"Sub","json")
			}.to change(FinanceWater,:count).by(0)

			expect(response.status).to eq 200
			expect(response.body).to match (/New amount must be greater than or equal to 0.0/)
		end

		it "failure html" do
			expect{
				post :modify,modify_params(999,"Sub","html")
			}.to change(FinanceWater,:count).by(0)
			expect(response.status).to eq 302
			expect(response.body).to redirect_to new_user_finance_water_path(users(:user_one))
			expect(flash[:notice].to_s).to match (/New amount must be greater than or equal to 0.0/)
		end

		it "success json" do
			expect{
				post :modify,modify_params(10,"Add","json")
			}.to change(FinanceWater,:count).by(1)

			expect(response.status).to eq 200
			expect(response.body).to match (/userid.*status.*reasons.*score.*e_cash.*waterno/)
		end

		it "success html" do
			expect{
				post :modify,modify_params(1,"Sub","html")
			}.to change(FinanceWater,:count).by(1)

			expect(response.status).to eq 302
			expect(response).to redirect_to show_user_finance_water_path(users(:user_one))
		end
	end

	def modify_params(amount,symbol,format)
		{
			'system' => 'mypost4u',
			'channel'  => 'spec_fixtures',
			'userid'  => users(:user_one)['userid'],
			'symbol'  => symbol,
			'amount'  => amount,
			'operator'  => 'spec_script',
			'reason'  => 'test',
			'datetime'  => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
			'watertype' => 'score' ,
			'format' => format
		}
	end
end