# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "snowfinch/collector/version"

Gem::Specification.new do |s|
  s.name        = "snowfinch-collector"
  s.version     = Snowfinch::Collector::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joao Carlos"]
  s.email       = ["mail@joao-carlos.com"]
  s.homepage    = ""
  s.summary     = %q{Snowfinch collector}
  s.description = %q{Collector gem for snowfinch.}

  s.rubyforge_project = "snowfinch-collector"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "bson_ext"
  s.add_dependency "mongo"
  s.add_dependency "rack"
  s.add_dependency "tzinfo"
end
