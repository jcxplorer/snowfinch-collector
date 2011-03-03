require "cgi"

def app
  Snowfinch::Collector
end

def path(parts={})
  "/?" + parts.each.map { |k,v| k.to_s + "=" + CGI.escape(v) }.join("&")
end

def token
  Snowfinch::Collector.db["sites"].find_one["_id"].to_s
end

def freeze_utc_time(*args)
  Timecop.freeze(Time.utc(*args))
end
