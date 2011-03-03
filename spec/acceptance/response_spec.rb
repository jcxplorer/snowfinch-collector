require "spec_helper"

feature "Response" do

  scenario "GET request" do
    get path(:token => token, :uri => "http://rails.fi/", :visitorId => "CAFE")
    
    empty_gif = "R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="

    last_response.status.should == 200
    last_response.headers["Content-Type"].should == "image/gif"
    Base64.encode64(last_response.body).strip.should == empty_gif
  end

end
