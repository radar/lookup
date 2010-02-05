require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'spec/rake/spectask'

require 'jeweler'
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
  s.add_dependency("hpricot", "0.8.1")
  
  s.require_path = 'lib'
  s.autorequire = "lookup"
  s.files = %w(LICENSE README.md Rakefile TODO) + Dir.glob("{lib,spec,bin,doc}/**/*")
end
Jeweler::GemcutterTasks.new

begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end

require 'spec/rake/spectask'
desc 'Default: run unit tests.'
task :default => :spec

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.libs = %w(lib spec)
  t.spec_opts << "-c"
  t.ruby_opts << "-rubygems"
end
