$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
ENV['HOME'] = File.dirname(__FILE__)

require 'rubygems'
require 'fakeweb'
require 'lookup'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

end