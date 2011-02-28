require "spec_helper"

feature "Data collection" do

  background do
    @time = Time.utc(2011, 11, 11, 11, 11)
    Timecop.freeze(@time)
  end

  let :page_counts do
    Snowfinch::Collector.db["page_counts"]
  end

  let :site_counts do
    Snowfinch::Collector.db["site_counts"]
  end

  let :page_referrers do
    Snowfinch::Collector.db["page_referrers"]
  end

  let :site_referrers do
    Snowfinch::Collector.db["site_referrers"]
  end

  let :visits do
    Snowfinch::Collector.db["visits"]
  end

  let :hour do
    Time.utc(2011, 11, 11, 11, 0)
  end

  scenario "A user comes directly to the site" do
    get path(:token => "X3", :uri => "http://rails.fi/", :visitorId => "CAFE",
             :visitorName => "Jenny")

    page_counts.count.should == 1
    page_counts.last["hour"].should == hour
    page_counts.last["pageviews"].should == 1
    page_counts.last["site"].should == "X3"
    page_counts.last["uri"].should == "http://rails.fi/"

    site_counts.count.should == 1
    site_counts.last["hour"].should == hour
    site_counts.last["pageviews"].should == 1
    site_counts.last["site"].should == "X3"
    site_counts.last["visits"].should == 1

    page_referrers.count.should == 1
    page_referrers.last["count"].should == 1
    page_referrers.last["host"].should == nil
    page_referrers.last["hour"].should == hour
    page_referrers.last["uri"].should == "http://rails.fi/"
    page_referrers.last["site"].should == "X3"

    site_referrers.count.should == 1
    site_referrers.last["host"].should == nil
    site_referrers.last["hour"].should == hour
    site_referrers.last["site"].should == "X3"
    site_referrers.last["count"].should == 1

    visits.count.should == 1
    visits.last["visitor"]["id"].should == "CAFE"
    visits.last["visitor"]["name"].should == "Jenny"
    visits.last["site"].should == "X3"
    visits.last["pages"].should == ["http://rails.fi/"]
    visits.last["heartbeats"]["first"].should == @time
    visits.last["heartbeats"]["last"].should == @time
  end

  scenario "A user visits a second page on the site" do
    get path(:token => "X3", :uri => "http://rails.fi/", :visitorId => "CAFE",
             :visitorName => "Jenny")

    new_time = @time + 25
    Timecop.freeze(new_time)

    get path(:token => "X3", :uri => "http://rails.fi/posts",
             :referrer => "http://rails.fi/", :visitorId => "CAFE",
             :visitorName => "Jenny")

    page_counts.count.should == 2
    page_counts.last["pageviews"].should == 1
    page_counts.last["uri"].should == "http://rails.fi/posts"

    site_counts.count.should == 1
    site_counts.last["pageviews"].should == 2
    site_counts.last["visits"].should == 1

    page_referrers.count.should == 2
    page_referrers.last["count"].should == 1
    page_referrers.last["host"].should == "rails.fi"
    page_referrers.last["uri"].should == "http://rails.fi/posts"

    site_referrers.count.should == 2
    site_referrers.last["host"].should == "rails.fi"
    site_referrers.last["count"].should == 1

    visits.count.should == 1
    visits.last["pages"].should == ["http://rails.fi/", "http://rails.fi/posts"]
    visits.last["heartbeats"]["first"].should == @time
    visits.last["heartbeats"]["last"].should == new_time
  end

  scenario "Two users visit the same site" do
    get path(:token => "X3", :uri => "http://rails.fi/", :visitorId => "A1")
    get path(:token => "X3", :uri => "http://rails.fi/", :visitorId => "B2")
    
    page_counts.count.should == 1
    page_counts.last["pageviews"].should == 2

    site_counts.count.should == 1
    site_counts.last["pageviews"].should == 2
    site_counts.last["visits"].should == 2

    visits.count.should == 2
  end

  scenario "URI with HTTPS" do
    get path(:token => "X3", :uri => "https://rails.fi/posts",
             :visitorId => "A1")

    page_counts.last["uri"].should == "http://rails.fi/posts"
    page_referrers.last["uri"].should == "http://rails.fi/posts"
    visits.last["pages"].should == ["http://rails.fi/posts"]
  end

  scenario "URIs with www" do
    get path(:token => "X3", :uri => "http://www.rails.fi/posts",
             :visitorId => "A1", :referrer => "http://www.rails.fi/")

    page_counts.last["uri"].should == "http://rails.fi/posts"
    page_referrers.last["host"].should == "rails.fi"
    page_referrers.last["uri"].should == "http://rails.fi/posts"
    site_referrers.last["host"].should == "rails.fi"
    visits.last["pages"].should == ["http://rails.fi/posts"]
  end

end
