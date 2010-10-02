# -*- encoding: utf-8 -*-
require File.expand_path("../lib/lookup/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "lookup"
  s.version     = Lookup::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = []
  s.email       = []
  s.homepage    = "http://rubygems.org/gems/lookup"
  s.summary     = "TODO: Write a gem summary"
  s.description = "TODO: Write a gem description"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "lookup"

  s.add_development_dependency "bundler", ">= 1.0.0"
  
  s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
  s.add_dependency(%q<nokogiri>, [">= 0"])
  s.add_dependency(%q<activerecord>, [">= 2.3.8"])
  s.add_dependency(%q<webmock>, [">= 0"])

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
