require "cgi"

def app
  Snowfinch::Collector
end

def path(parts={})
  "/?" + parts.each.map { |k,v| k.to_s + "=" + CGI.escape(v) }.join("&")
end
