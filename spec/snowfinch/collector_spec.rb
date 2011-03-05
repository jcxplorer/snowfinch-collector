require "spec_helper"

describe Snowfinch::Collector do

  describe ".db", :database => false do
    context "default" do
      it "returns a database 'snowfinch' with a default connection" do
        connection = mock("Mongo::Connection")
        database = mock("Mongo::Database")
        Mongo::Connection.should_receive(:new).with(no_args).
          and_return(connection)
        connection.should_receive(:db).with("snowfinch").and_return(database)

        Snowfinch::Collector.db.should == database
      end

      it "returns the same object accross calls" do
        first_id  = Snowfinch::Collector.db.object_id
        second_id = Snowfinch::Collector.db.object_id

        first_id.should == second_id
      end
    end
  end

  describe ".db=", :database => false do
    it "sets the Mongo::Database object to be used" do
      database = Mongo::Connection.new.db("snowfinch")
      Snowfinch::Collector.db = database
      Snowfinch::Collector.db.should == database
    end
  end

  describe ".sanitize_uri" do
    it "turns https into http" do
      original_uri = "https://snowfinch.net/posts"
      expected_uri = "http://snowfinch.net/posts"
      Snowfinch::Collector.sanitize_uri(original_uri).should == expected_uri
    end

    it "removes www." do
      original_uri = "http://www.snowfinch.net/archive"
      expected_uri = "http://snowfinch.net/archive"
      Snowfinch::Collector.sanitize_uri(original_uri).should == expected_uri
    end

    it "removes a slash at the end of the path" do
      original_uri = "http://snowfinch.net/archive/"
      expected_uri = "http://snowfinch.net/archive"
      Snowfinch::Collector.sanitize_uri(original_uri).should == expected_uri
    end

    it "removes the query part" do
      original_uri = "http://snowfinch.net/?source=google"
      expected_uri = "http://snowfinch.net/"
      Snowfinch::Collector.sanitize_uri(original_uri).should == expected_uri
    end

    it "removes the fragment part" do
      original_uri = "http://snowfinch.net/about#contact"
      expected_uri = "http://snowfinch.net/about"
      Snowfinch::Collector.sanitize_uri(original_uri).should == expected_uri
    end
  end

  describe ".hash_uri" do
    it "returns a SHA1 hash of the URI in base 62" do
      uri = "http://snowfinch.net/about"
      Snowfinch::Collector.hash_uri(uri).should == "jjvMHRNTpBvTWe5Nm0YIjHufcdA"

      uri = "http://snowfinch.net/"
      Snowfinch::Collector.hash_uri(uri).should == "acrfzPFTC4qJH0SLjgo4611dj2h"
    end
  end

end
