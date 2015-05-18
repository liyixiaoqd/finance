require "rails_helper"

RSpec.describe "routes for online_pay", :type => :routing do
  it "routes /show_single_detail to the online_pay controller" do
    expect(get("pay/1/show_single_detail")).
      to route_to(  
      	:controller => "online_pay",
  	:action => "show_single_detail",
  	:online_pay_id =>"1")
  end

  it "routes /show  to the online_pay controller" do
    expect(get("pay/1/show")).
      to route_to(  
      	:controller => "online_pay",
  	:action => "show",
  	:userid =>"1")
  end
end