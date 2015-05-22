require 'rails_helper'
require "support/render_views"

describe AdminManageController do
	context "sign_in" do
		it "get no session" do
			get :sign_in
			expect(response).to render_template(:sign_in)
			expect(request.session[:admin]).to eq nil
		end
		it "get by session" do
			request.session[:admin]="admin"
			get :sign_in
			expect(response).to redirect_to admin_manage_sign_index_path
		end

		it "post succ" do
			expect(request.session[:admin]).to eq nil
			post :sign_in,:admin=>{:admin_name=>'admin',:admin_passwd_encryption=>"#{Digest::MD5.hexdigest('passwd')}"}
			expect(response).to redirect_to admin_manage_sign_index_path
			expect(request.session[:admin]).to eq "admin"
		end

		it "post fail" do
			expect(request.session[:admin]).to eq nil
			post :sign_in,:admin=>{:admin_name=>'admin',:admin_passwd_encryption=>"#{Digest::MD5.hexdigest('wrong_passwd')}"}
			expect(response).to render_template(:sign_in)
			expect(request.session[:admin]).to eq nil
		end
	end

	context 'sign_out' do
		it "succ" do
			request.session[:admin]="admin"
			post :sign_out
			expect(response).to redirect_to admin_manage_sign_in_path
			expect(request.session[:admin]).to eq nil
		end
	end
end