# -*- encoding: utf-8 -*-
require File.expand_path("../lib/lookup/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "lookup"
  s.version     = Lookup::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = []
  s.email       = []
  s.homepage    = "http://rubygems.org/gems/lookup"
  s.summary     = "Lazy man's RI"
  s.description = "Lazy man's RI"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.1"
  s.add_development_dependency "webmock", "~> 1.6"
  
  s.add_dependency(%q<sqlite3>, [">= 1.2.5"])
  s.add_dependency(%q<nokogiri>, [">= 0"])
  s.add_dependency(%q<activerecord>, [">= 2.3.8"])

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
