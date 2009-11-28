require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'spec/rake/spectask'

require 'jeweler'
Jeweler::GemcutterTasks.new

AUTHOR = "Ryan Bigg"
EMAIL = "radarlistener@gmail.com"
HOMEPAGE = "http://gitpilot.com"
SUMMARY = "A gem that provides a lazy man's ri"

Jeweler::Tasks.new do |s|
  s.name = "lookup"
  s.version = File.read("VERSION")
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.executables << "lookup"

  s.add_dependency("sqlite3-ruby", "1.2.5")
  
  s.require_path = 'lib'
  s.autorequire = "lookup"
  s.files = %w(LICENSE README.md Rakefile TODO) + Dir.glob("{lib,spec,bin,doc}/**/*")
end
