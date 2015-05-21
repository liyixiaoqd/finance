require 'rails_helper'

describe User do
	fixtures :users

	before(:all) do
		@user=User.new({:system=>'spec_test'})
	end

	after(:all) do
		@user.destroy
	end

	context "attributes test" do
		it "should eq 0.0" do
			expect(@user.e_cash).to eq 0.0
		end
	end


	context "raise_expection" do
		it "should raise expection" do
			expect{@user.save!}.to raise_error(ActiveRecord::RecordInvalid)
		end

		it "should unique_valid" do	
			u=User.create( users(:user_one).attributes )		
			expect(			
				u.errors.messages[:base][0]
			).to eq "user has exists"
		end
	end
end
