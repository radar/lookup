require 'fileutils'

module APILookup

  class MissingHome < StandardError
  end
  
  class LookupBase < ActiveRecord::Base
    include FindByHash
  end
  
  if ENV["HOME"].nil?
    puts "The HOME environment variable should be set so lookup knows where"
    puts "to store it's lookup database."
    raise MissingHome, "HOME must be set to know where to store our local db."
  end
 
  LookupBase.establish_connection(:adapter => "sqlite3", 
    :database => File.join(ENV["HOME"], ".lookup", "lookup.sqlite3"))

  class Api < LookupBase
    set_table_name "apis"
    has_many :constants, :class_name => "APILookup::Constant"
    
    def update_methods!
      entries = []
      constants = []
      doc = Net::HTTP.get(URI.parse("#{url}/fr_method_index.html"))
      
      # Actual HTML on Ruby doc site is invalid. 
      # This makes it valid.
      doc = Nokogiri::HTML(doc.gsub(/<a(.*?)>(.*?)<\/a>/) { "<a#{$1}>#{$2.gsub("<", "&lt;").gsub("&gt;", ">")}" })
      doc.css("a").each do |a|
        names = a.text.split(" ")
        next if names.empty? 
        method = names[0]
        constant = names[1].gsub(/[\(|\)]/, "")
        # The same constant can be defined twice in different APIs, be wary!
        url = self.url + "/classes/" + constant.gsub("::", "/") + ".html"
        constant = self.constants.find_or_create_by_hash(:name => constant, :url => url)
        
        url = self.url + "/" + a["href"]
        constant.entries.find_or_create_by_hash(:name => method, :url => url)
      end
      
      # entries.each_slice(100) do |methods|
      #   LookupBase.connection.execute("INSERT INTO entries (name, url) ")
      # end
    end
    
    def update_classes!
      doc = Nokogiri::HTML(Net::HTTP.get(URI.parse("#{url}/fr_class_index.html")))
      doc.css("a").each do |a|
        constant = self.constants.find_or_create_by_name_and_url(a.text, self.url + "/" + a["href"])
      end
    end
  end

  class Constant < LookupBase
    set_table_name "constants"
    belongs_to :api, :class_name => "APILookup::Api"
    has_many :entries, :class_name => "APILookup::Entry"
  end
  
  class Entry < LookupBase
    set_table_name "entries"
    belongs_to :constant, :class_name => "APILookup::Constant"
    
    delegate :api, :to => :constant
  end

end

class SetupTables < ActiveRecord::Migration
  def self.connection
    APILookup::Api.connection
  end

  def self.up
    create_table :apis do |t|
      t.string :name, :url
    end
    
    create_table :entries do |t|
      t.string :name, :url
      t.references :constant
      t.integer :weighting, :default => 0
      t.integer :count, :default => 0
    end
    
    create_table :constants do |t|
      t.string :name, :url
      t.references :api
      t.integer :weighting, :default => 0
      t.integer :count, :default => 0
    end
  end
end

FileUtils.mkdir_p(File.join(ENV["HOME"],".lookup"))

if !APILookup::Api.table_exists? && 
   !APILookup::Constant.table_exists? && 
   !APILookup::Entry.table_exists?
  SetupTables.up
  APILookup.update!
end