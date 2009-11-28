require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'spec/rake/spectask'

require 'jeweler'
Jeweler::GemcutterTasks.new

GEM = "lookup"
GEM_VERSION = "0.1.0"
AUTHOR = "Ryan Bigg"
EMAIL = "radarlistener@gmail.com"
HOMEPAGE = "http://gitpilot.com"
SUMMARY = "A gem that provides a lazy man's ri"

Jeweler::Tasks.new do |s|
  s.name = GEM
  s.add_dependency("sqlite3-ruby", "1.2.5")
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.executables << "lookup"
  
  # Uncomment this to add a dependency
  # s.add_dependency "foo"
  
  s.require_path = 'lib'
  s.autorequire = GEM
  s.files = %w(LICENSE README.md Rakefile TODO) + Dir.glob("{lib,spec,bin,doc}/**/*")
end
