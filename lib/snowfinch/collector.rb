require "base64"
require "mongo"
require "rack"
require "rack/request"
require "uri"

module Snowfinch
  module Collector
    
    EMPTY_GIF = "R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
    RESPONSE  = [Base64.decode64(EMPTY_GIF)]
    HEADERS   = { "Content-Type" => "image/gif" }

    def self.call(env)
      params = Rack::Request.new(env).params

      uri = params["uri"].sub(/^https?:\/\/(www\.)?/, "http://")
      referrer = params["referrer"].to_s.sub(/^https?:\/\/(www\.)?/, "http://")
      visitor_name = params["visitorName"]
      visitor_id = params["visitorId"]
      site = params["token"]

      time = Time.now.utc
      hour = Time.utc(time.year, time.month, time.day, time.hour)

      uri_host = URI.regexp.match(uri)[4]

      referrer_match  = URI.regexp.match(referrer)
      referrer_host   = referrer_match[4] if referrer_match

      within_site = uri_host == referrer_host

      visit_update = {
        :$set => { "visitor" => { "name" => visitor_name,
                                  "id" => visitor_id } },
        :$push => { "pages" => uri }
      }

      if within_site
        visit_inc = 0
        visit_update[:$set].merge!({
          "heartbeats.last" => time
        })
      else
        visit_inc = 1
        visit_update[:$set].merge!({
          "heartbeats" => { "first" => time, "last" => time }
        })
      end

      db["page_counts"].update(
        { "site" => site, "uri" => uri, "hour" => hour },
        { :$inc => { "pageviews" => 1 } },
        { :upsert => true }
      )

      db["site_counts"].update(
        { "site" => site, "hour" => hour },
        { :$inc => { "pageviews" => 1, "visits" => visit_inc } },
        { :upsert => true }
      )

      db["page_referrers"].update(
        { "site" => site, "uri" => uri, "hour" => hour,
          "host" => referrer_host },
        { :$inc => { "count" => 1 } },
        { :upsert => true }
      )

      db["site_referrers"].update(
        { "site" => site, "hour" => hour, "host" => referrer_host },
        { :$inc => { "count" => 1 } },
        { :upsert => true }
      )

      if visitor_id
        db["visits"].update(
          { "site" => site, "visitor.id" => visitor_id },
          visit_update,
          { :upsert => true }
        )
      end

      [200, HEADERS, RESPONSE]
    rescue
      [400, {}, []]
    end

    def self.db
      @@db ||= Mongo::Connection.new.db("snowfinch")
    end

    def self.db=(database)
      @@db = database
    end

  end
end
