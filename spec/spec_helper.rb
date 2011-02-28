require "bundler"
Bundler.require(:test)

require "snowfinch/collector"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:each) do
    Snowfinch::Collector.db = nil

    unless example.metadata[:database] == false
      Snowfinch::Collector.db = Mongo::Connection.new.db("snowfinch_test")
      Snowfinch::Collector.db.collections.each do |collection|
        collection.drop unless collection.name.match(/^system\./)
      end
    end
  end

  config.after(:suite) do
    Timecop.return
  end
end
