require 'rails_helper'
require "support/render_views"

describe TransactionReconciliationController do
	describe "transaction reconciliation call" do
		it "get" do
			request.session[:admin]="admin"
			get :index

			expect(response.status).to eq(200)
		end

		it "report" do
			request.session[:admin]="admin"		
			post :report,init_report_params()

			expect(response.status).to eq(200)
			expect(response.body).to match (/总交易金额/)
			expect(response.body).to match (/总交易比数/)
		end
	end

	let(:init_report_params) do
		{
			'payway'=>'',
			'paytype'=>'',
			'start_time'=>Time.now.strftime("%Y%m%d"),
			'end_time'=>(Time.now+1.day).strftime("%Y%m%d")
		}
	end
end