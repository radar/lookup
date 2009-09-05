$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
ENV['HOME'] = File.dirname(__FILE__)

require 'rubygems'
require 'fakeweb'
require 'lookup'