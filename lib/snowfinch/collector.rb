require "base64"
require "mongo"
require "rack"
require "rack/request"
require "uri"
require "digest/sha1"
require "radix62"
require "snowfinch/collector/click"

module Snowfinch
  module Collector
    
    EMPTY_GIF = "R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
    RESPONSE  = [Base64.decode64(EMPTY_GIF)]
    HEADERS   = { "Content-Type" => "image/gif" }

    OK          = [200, HEADERS, RESPONSE]
    BAD_REQUEST = [400, {}, []]

    def self.call(env)
      params = Rack::Request.new(env).params

      click = Click.new :token => params["token"],
                        :uri => params["uri"],
                        :uuid => params["uuid"],
                        :referrer => params["referrer"]
      
      if click.save
        OK
      else
        BAD_REQUEST
      end
    rescue
      BAD_REQUEST
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
