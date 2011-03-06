require "cgi"

def app
  Snowfinch::Collector
end

def path_without_defaults(parts={})
  "/?" + parts.each.map { |k,v| k.to_s + "=" + CGI.escape(v) }.join("&")
end

def path(parts={})
  parts[:token] ||= token
  parts[:uri] ||= "http://snowfinch.net/"
  parts[:uuid] ||= "8e41cb1f-72f1-4ed5-bb29-84151737cc0a"
  path_without_defaults(parts)
end

def token
  Snowfinch::Collector.db["sites"].find_one["_id"].to_s
end

def freeze_utc_time(*args)
  Timecop.freeze(Time.utc(*args))
end
