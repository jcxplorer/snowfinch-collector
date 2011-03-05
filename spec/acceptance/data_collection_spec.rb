require "spec_helper"

feature "Data collection" do

  let :sites do
    Snowfinch::Collector.db["sites"].find.to_a
  end
  
  let :site_counts do
    Snowfinch::Collector.db["site_counts"].find.to_a
  end

  let :page_counts do
    Snowfinch::Collector.db["page_counts"].find({}, :sort => "_id").to_a
  end

  background do
    @time = Time.utc(2011, 11, 11, 11, 11)
    Timecop.freeze(@time)
  end

  scenario "Multiple pageviews at different times" do
    freeze_utc_time(2011, 2, 12, 7)
    get path(:token => token, :uri => "http://snowfinch.net/posts")

    freeze_utc_time(2011, 6, 4, 10)
    get path(:token => token, :uri => "http://snowfinch.net/archive")

    freeze_utc_time(2011, 6, 4, 15)
    get path(:token => token, :uri => "http://snowfinch.net/")

    freeze_utc_time(2011, 6, 4, 15)
    get path(:token => token, :uri => "http://snowfinch.net/posts")

    freeze_utc_time(2011, 6, 4, 15)
    get path(:token => token, :uri => "http://snowfinch.net/posts")

    freeze_utc_time(2012, 1, 1, 4)
    get path(:token => token, :uri => "http://snowfinch.net/")

    site_counts.count.should == 2
    page_counts.count.should == 4

    (site_counts + page_counts).each do |doc|
      doc["s"].should == BSON::ObjectId(token)
    end

    site_counts[0]["y"].should == 2011
    site_counts[0]["c"].should == 5
    site_counts[0]["2"]["c"].should == 1
    site_counts[0]["2"]["12"]["c"].should == 1
    site_counts[0]["2"]["12"]["9"]["c"].should == 1
    site_counts[0]["6"]["c"].should == 4
    site_counts[0]["6"]["4"]["c"].should == 4
    site_counts[0]["6"]["4"]["13"]["c"].should == 1
    site_counts[0]["6"]["4"]["18"]["c"].should == 3

    site_counts[1]["y"].should == 2012
    site_counts[1]["c"].should == 1
    site_counts[1]["1"]["c"].should == 1
    site_counts[1]["1"]["1"]["c"].should == 1
    site_counts[1]["1"]["1"]["6"]["c"].should == 1

    page_counts[0]["u"].should == "http://snowfinch.net/posts"
    page_counts[0]["y"].should == 2011
    page_counts[0]["c"].should == 3
    page_counts[0]["2"]["c"].should == 1
    page_counts[0]["2"]["12"]["c"].should == 1
    page_counts[0]["2"]["12"]["9"]["c"].should == 1
    page_counts[0]["6"]["c"].should == 2
    page_counts[0]["6"]["4"]["c"].should == 2
    page_counts[0]["6"]["4"]["18"]["c"].should == 2

    page_counts[1]["u"].should == "http://snowfinch.net/archive"
    page_counts[1]["y"].should == 2011
    page_counts[1]["c"].should == 1
    page_counts[1]["6"]["c"].should == 1
    page_counts[1]["6"]["4"]["c"].should == 1
    page_counts[1]["6"]["4"]
    page_counts[1]["6"]["4"]["13"]["c"].should == 1

    page_counts[2]["u"].should == "http://snowfinch.net/"
    page_counts[2]["y"].should == 2011
    page_counts[2]["c"].should == 1
    page_counts[2]["6"]["c"].should == 1
    page_counts[2]["6"]["4"]["c"].should == 1
    page_counts[2]["6"]["4"]["18"]["c"].should == 1

    page_counts[3]["u"].should == "http://snowfinch.net/"
    page_counts[3]["y"].should == 2012
    page_counts[3]["c"].should == 1
    page_counts[3]["1"]["c"].should == 1
    page_counts[3]["1"]["1"]["c"].should == 1
    page_counts[3]["1"]["1"]["6"]["c"].should == 1
  end

end
