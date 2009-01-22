require 'rubygems'
gem 'activerecord', '2.1'
require 'activerecord'
require 'yaml'
require 'hpricot'
require 'net/http'

DEBUG = false

Dir.glob('models/*').each { |f| require f }

ActiveRecord::Base.establish_connection(YAML::load(File.open("database.yml")))