require "spec_helper"

feature "Response" do

  scenario "GET request" do
    get path(:token => token, :uri => "http://snowfinch.net/", :uuid => "CAFE")
    
    empty_gif = "R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="

    last_response.status.should == 200
    last_response.headers["Content-Type"].should == "image/gif"
    Base64.encode64(last_response.body).strip.should == empty_gif
  end

  scenario "Invalid requests" do
    get path_without_defaults
    last_response.status.should == 400

    get path_without_defaults(:token => token)
    last_response.status.should == 400

    get path_without_defaults(:token => token, :uri => "http://snowfinch.net/")
    last_response.status.should == 400

    get path_without_defaults(:token => token,
                              :uuid => "c2f6b003-e7e3-4bac-b69d-8b3d54ebab62")
    last_response.status.should == 400
  end

end
