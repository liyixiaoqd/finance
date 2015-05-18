require 'rails_helper'

describe TransactionReconciliationController do
	describe "transaction reconciliation call" do
		it "get" do
			request.session[:admin]="admin"
			get :index

			expect(response.status).to eq(200)
		end
	end
end