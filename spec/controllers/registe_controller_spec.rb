require 'rails_helper'
require "support/render_views"

describe RegisteController do
	fixtures :users

	let!(:set_session) do
		request.session[:admin]="admin"
		get :index
	end

	describe "get index" do
		it "get index status" do
			expect(response.status).to eq(200)
		end
		it "assigns index users" do
			expect(assigns(:users)).to eq([users(:one)])
		end
		it "get index template" do
			expect(response).to render_template("index")
		end

		context "get response.body" do
			it "get index say" do
				expect(response.body).to match /用户ID/im
			end
		end
	end
end