$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
ENV['HOME'] = File.dirname(__FILE__)

require 'rubygems'
require 'webmock'

def here
  Pathname.new(File.dirname(__FILE__))
end

def apis
  here + "apis"
end

def entries(api)
  File.read(apis + api + "methods.html")
end

def classes(api)
  File.read(apis + api + "classes.html")
end

include WebMock

WebMock.disable_net_connect!

stub_request(:get, "http://api.rubyonrails.org/fr_method_index.html").to_return(:body => entries("rails"))
stub_request(:get, "http://api.rubyonrails.org/fr_class_index.html").to_return(:body => classes("rails"))

stub_request(:get, "http://www.ruby-doc.org/core/fr_method_index.html").to_return(:body => entries("1.8"))
stub_request(:get, "http://www.ruby-doc.org/core/fr_class_index.html").to_return(:body => classes("1.8"))

stub_request(:get, "http://ruby-doc.org/ruby-1.9/fr_method_index.html").to_return(:body => entries("1.9"))
stub_request(:get, "http://ruby-doc.org/ruby-1.9/fr_class_index.html").to_return(:body => classes("1.9"))


require 'lookup'
require 'spec'
require 'spec/autorun'
require 'pathname'

Spec::Runner.configure do |config|
  
end