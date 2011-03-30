require "bson"
require "cgi"
require "time"
require "tzinfo"
require "uri"

module Snowfinch
  module Collector
    class Click

      def initialize(attributes={})
        @attributes = attributes
      end

      def save
        if uri && uuid
          update_site_count
          update_page_count
          update_visit
          update_visitor
          update_sensors
          true
        else
          false
        end
      end

      private

      def site_id
        @site_id ||= BSON::ObjectId(@attributes[:token])
      end

      def uuid
        @uuid ||= @attributes[:uuid]
      end

      def uri
        @uri ||= begin
          uri = @attributes[:uri]
          uri && Snowfinch::Collector.sanitize_uri(uri)
        end
      end

      def uri_hash
        @uri_hash ||= Snowfinch::Collector.hash_uri(uri)
      end

      def referrer
        @referrer ||= @attributes[:referrer]
      end

      def site
        @site ||= Snowfinch::Collector.db["sites"].find_one(site_id)
      end

      def time
        @time ||= TZInfo::Timezone.get(site["tz"]).current_period_and_time.first
      end

      def sensors
        @sensors ||= site["sensors"]
      end

      def matching_sensors
        matching_query_sensors + matching_host_sensors
      end

      def matching_query_sensors
        query_string = URI.parse(@attributes[:uri]).query

        if query_string
          query_parts = CGI.parse(query_string)

          matches = sensors.find_all do |sensor|
            if sensor["type"] == "query"
              query_parts.any? do |key, value|
                sensor["key"] == key && value.include?(sensor["value"])
              end
            end
          end

          matches.map { |sensor| sensor["id"] }
        else
          []
        end
      end

      def matching_host_sensors
        if referrer && !referrer.empty?
          referrer_host = URI.parse(referrer).host

          matches = sensors.find_all do |sensor|
            if sensor["type"] == "host"
              sensor["hosts"].any? do |sensor_host|
                referrer_host =~ /^(\S+\.)?#{sensor_host}$/
              end
            end
          end

          matches.map { |sensor| sensor["id"] }
        else
          []
        end
      end

      def hourly_increment
        @hourly_increment ||= { 
          "c" => 1,
          "#{time.mon}.c" => 1,
          "#{time.mon}.#{time.day}.c" => 1,
          "#{time.mon}.#{time.day}.#{time.hour}.c" => 1
        }
      end

      def update_site_count
        Snowfinch::Collector.db["site_counts"].update(
          { "s" => site_id, "y" => time.year },
          { :$inc => hourly_increment },
          { :upsert => true }
        )
      end

      def update_page_count
        Snowfinch::Collector.db["page_counts"].update(
          { "s" => site_id, "u" => uri, "y" => time.year },
          { :$inc => hourly_increment },
          { :upsert => true }
        )
      end

      def update_visit
        Snowfinch::Collector.db["visits"].update(
          {
            "s" => site_id,
            "v" => uuid,
            "h" => { :$gt => (Time.now.to_i - 15 * 60) }
          },
          {
            :$addToSet => { "p" => uri_hash },
            :$set => { "h" => Time.now.to_i },
            :$inc => { "c" => 1 }
          },
          { :upsert => true }
        )
      end

      def update_visitor
        Snowfinch::Collector.db["visitors"].update(
          { "s" => site_id, "u" => uuid, "d" => time.to_date.to_s },
          { :$inc => { "c" => 1 } },
          { :upsert => 1 }
        )
      end

      def update_sensors
        matching_sensors.each do |id|
          Snowfinch::Collector.db["sensor_counts"].update(
            { "s" => site_id, "y" => time.year, "id" => id },
            { :$inc => hourly_increment },
            { :upsert => true }
          )
        end
      end

    end
  end
end
