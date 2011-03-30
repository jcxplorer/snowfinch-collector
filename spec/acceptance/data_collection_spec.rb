require "spec_helper"

feature "Data collection" do

  let(:homepage) { "http://snowfinch.net/" }

  let :sites do
    Snowfinch::Collector.db["sites"].find.to_a
  end
  
  let :site_counts do
    Snowfinch::Collector.db["site_counts"].find.to_a
  end

  let :page_counts do
    Snowfinch::Collector.db["page_counts"].find({}, :sort => "_id").to_a
  end

  let :sensor_counts do
    Snowfinch::Collector.db["sensor_counts"].find({}, :sort => "_id").to_a
  end

  let :visits do
    Snowfinch::Collector.db["visits"].find({}, :sort => "_id").to_a
  end

  let :visitors do
    Snowfinch::Collector.db["visitors"].find({}, :sort => "_id").to_a
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

  scenario "Multiple visits" do
    archive  = "http://snowfinch.net/archive"

    freeze_utc_time(2011, 1, 1, 10, 0)
    get path(:uuid => "A", :token => token, :uri => homepage)
    get path(:uuid => "B", :token => token, :uri => homepage)

    freeze_utc_time(2011, 1, 1, 10, 10)
    get path(:uuid => "A", :token => token, :uri => homepage)

    freeze_utc_time(2011, 1, 1, 10, 15)
    get path(:uuid => "B", :token => token, :uri => homepage)

    freeze_utc_time(2011, 1, 1, 10, 30)
    get path(:uuid => "C", :token => token, :uri => homepage)

    freeze_utc_time(2011, 1, 1, 10, 44, 59)
    get path(:uuid => "C", :token => token, :uri => archive)

    freeze_utc_time(2011, 1, 1, 10, 55)
    get path(:uuid => "A", :token => token, :uri => homepage)

    freeze_utc_time(2011, 1, 1, 11, 5)
    get path(:uuid => "A", :token => token, :uri => homepage)

    visits.count.should == 5
    visits.each { |doc| doc["s"].should == BSON::ObjectId(token) }

    visits[0]["p"].should == [Snowfinch::Collector.hash_uri(homepage)]
    visits[0]["v"].should == "A"
    visits[0]["h"].should == Time.utc(2011, 1, 1, 10, 10).to_i
    visits[0]["c"].should == 2

    visits[1]["p"].should == [Snowfinch::Collector.hash_uri(homepage)]
    visits[1]["v"].should == "B"
    visits[1]["h"].should == Time.utc(2011, 1, 1, 10, 0).to_i
    visits[1]["c"].should == 1

    visits[2]["p"].should == [Snowfinch::Collector.hash_uri(homepage)]
    visits[2]["v"].should == "B"
    visits[2]["h"].should == Time.utc(2011, 1, 1, 10, 15).to_i
    visits[2]["c"].should == 1

    pages = [homepage, archive].map { |uri| Snowfinch::Collector.hash_uri(uri) }
    visits[3]["p"].should == pages
    visits[3]["v"].should == "C"
    visits[3]["h"].should == Time.utc(2011, 1, 1, 10, 44, 59).to_i
    visits[3]["c"].should == 2

    visits[4]["p"].should == [Snowfinch::Collector.hash_uri(homepage)]
    visits[4]["v"].should == "A"
    visits[4]["h"].should == Time.utc(2011, 1, 1, 11, 5).to_i
    visits[4]["c"].should == 2
  end

  scenario "Multiple visitors" do
    freeze_utc_time(2011, 1, 1, 23, 0)
    get path(:token => token, :uuid => "A", :uri => homepage)

    freeze_utc_time(2011, 1, 2)
    get path(:token => token, :uuid => "A", :uri => homepage)

    freeze_utc_time(2011, 1, 2)
    get path(:token => token, :uuid => "B", :uri => homepage)

    freeze_utc_time(2011, 1, 3)
    get path(:token => token, :uuid => "A", :uri => homepage)

    visitors.count.should == 3
    visitors

    visitors[0]["d"].should == "2011-01-02"
    visitors[0]["u"].should == "A"
    visitors[0]["c"].should == 2

    visitors[1]["d"].should == "2011-01-02"
    visitors[1]["u"].should == "B"
    visitors[1]["c"].should == 1

    visitors[2]["d"].should == "2011-01-03"
    visitors[2]["u"].should == "A"
    visitors[2]["c"].should == 1
  end

  scenario "Entries matching a query based sensor" do
    campaign_uri     = "http://snowfinch.net/?campaign=rr"
    both_sensors_uri = "http://snowfinch.net/?campaign=rr&from=email"

    campaign_sensor = {
      "id" => 12,
      "type" => "query",
      "key" => "campaign",
      "value" => "rr"
    }

    email_sensor = {
      "id" => 24,
      "type" => "query",
      "key" => "from",
      "value" => "email"
    }

    Snowfinch::Collector.db["sites"].update(
      { "_id" => BSON::ObjectId(token) },
      { :$set => { "sensors" => [campaign_sensor, email_sensor] } }
    )

    freeze_utc_time(2011, 11, 11, 20)
    get path(:token => token, :uri => campaign_uri)

    freeze_utc_time(2011, 11, 11, 20)
    get path(:token => token, :uri => campaign_uri)
    
    freeze_utc_time(2011, 11, 11, 21)
    get path(:token => token, :uri => both_sensors_uri)

    freeze_utc_time(2011, 11, 11, 21)
    get path(:token => token, :uri => homepage)

    sensor_counts.count.should == 2

    sensor_counts[0]["s"].should == BSON::ObjectId(token)
    sensor_counts[0]["id"].should == 12
    sensor_counts[0]["y"].should == 2011
    sensor_counts[0]["c"].should == 3
    sensor_counts[0]["11"]["c"].should == 3
    sensor_counts[0]["11"]["11"]["c"].should == 3
    sensor_counts[0]["11"]["11"]["22"]["c"].should == 2
    sensor_counts[0]["11"]["11"]["23"]["c"].should == 1

    sensor_counts[1]["s"].should == BSON::ObjectId(token)
    sensor_counts[1]["id"].should == 24
    sensor_counts[1]["y"].should == 2011
    sensor_counts[1]["c"].should == 1
    sensor_counts[1]["11"]["c"].should == 1
    sensor_counts[1]["11"]["11"]["c"].should == 1
    sensor_counts[1]["11"]["11"]["23"]["c"].should == 1
  end

  scenario "Entries matching a host based sensor" do
    facebook_referrer = "http://www.facebook.com/l.php"
    twitter_referrer = "http://twitter.com/jcxplorer"
    search_referrer = "http://duckduckgo.com/post.html"

    social_sensor = {
      "id" => 33,
      "type" => "host",
      "hosts" => ["facebook.com", "twitter.com"]
    }

    facebook_sensor = {
      "id" => 46,
      "type" => "host",
      "hosts" => ["facebook.com"]
    }

    Snowfinch::Collector.db["sites"].update(
      { "_id" => BSON::ObjectId(token) },
      { :$set => { "sensors" => [social_sensor, facebook_sensor] } }
    )

    freeze_utc_time(2011, 8, 2, 5)
    get path(:token => token, :uri => homepage, :referrer => twitter_referrer)

    freeze_utc_time(2011, 8, 2, 5)
    get path(:token => token, :uri => homepage, :referrer => search_referrer)

    freeze_utc_time(2011, 8, 10, 12)
    get path(:token => token, :uri => homepage, :referrer => facebook_referrer)

    freeze_utc_time(2011, 8, 10, 12)
    get path(:token => token, :uri => homepage, :referrer => twitter_referrer)

    sensor_counts.count.should == 2

    sensor_counts[0]["s"].should == BSON::ObjectId(token)
    sensor_counts[0]["id"].should == 33
    sensor_counts[0]["y"].should == 2011
    sensor_counts[0]["c"].should == 3
    sensor_counts[0]["8"]["c"].should == 3
    sensor_counts[0]["8"]["2"]["c"].should == 1
    sensor_counts[0]["8"]["2"]["8"]["c"].should == 1
    sensor_counts[0]["8"]["10"]["c"].should == 2
    sensor_counts[0]["8"]["10"]["15"]["c"].should == 2

    sensor_counts[1]["s"].should == BSON::ObjectId(token)
    sensor_counts[1]["id"].should == 46
    sensor_counts[1]["y"].should == 2011
    sensor_counts[1]["c"].should == 1
    sensor_counts[1]["8"]["c"].should == 1
    sensor_counts[1]["8"]["10"]["c"].should == 1
    sensor_counts[1]["8"]["10"]["15"]["c"].should == 1
  end

end
