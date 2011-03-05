require "base64"
require "mongo"
require "rack"
require "rack/request"
require "uri"
require "tzinfo"
require "digest/sha1"
require "radix62"

module Snowfinch
  module Collector
    
    EMPTY_GIF = "R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
    RESPONSE  = [Base64.decode64(EMPTY_GIF)]
    HEADERS   = { "Content-Type" => "image/gif" }

    def self.call(env)
      params  = Rack::Request.new(env).params
      site_id = BSON::ObjectId(params["token"])

      site = db["sites"].find_one(site_id)

      if site
        uri = sanitize_uri(params["uri"])

        visitor_name = params["visitor_name"]
        visitor_id = params["visitorId"]

        time = TZInfo::Timezone.get(site["tz"]).current_period_and_time.first

        db["site_counts"].update(
          { "s" => site_id, "y" => time.year },
          { :$inc =>
            { 
              "c" => 1,
              "#{time.mon}.c" => 1,
              "#{time.mon}.#{time.day}.c" => 1,
              "#{time.mon}.#{time.day}.#{time.hour}.c" => 1
            }
          },
          { :upsert => true }
        )

        db["page_counts"].update(
          { "s" => site_id, "u" => uri, "y" => time.year },
          { :$inc =>
            { 
              "c" => 1,
              "#{time.mon}.c" => 1,
              "#{time.mon}.#{time.day}.c" => 1,
              "#{time.mon}.#{time.day}.#{time.hour}.c" => 1
            }
          },
          { :upsert => true }
        )

        [200, HEADERS, RESPONSE]
      else
        [403, {}, []]
      end
    rescue
      [400, {}, []]
    end

    def self.db
      @db ||= Mongo::Connection.new.db("snowfinch")
    end

    def self.db=(database)
      @db = database
    end

    def self.sanitize_uri(uri)
      uri = uri.sub(/^https?:\/\/(www\.)?/, "http://")
      uri = URI.parse(uri)
      uri.path = uri.path.sub(/(.)\/$/, '\1')
      uri.query = nil
      uri.fragment = nil
      uri = uri.to_s
    end

    def self.hash_uri(uri)
      Digest::SHA1.hexdigest(uri).to_i(16).encode62
    end

  end
end
