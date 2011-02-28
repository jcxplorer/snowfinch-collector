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

end
