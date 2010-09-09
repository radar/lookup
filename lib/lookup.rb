require 'rubygems'
require 'bundler'
require 'net/http'

Bundler.setup
Bundler.require(:default)
require 'active_record'

module APILookup

  class << self
    def update!
      puts "Updating API, this may take a minute or two. Please be patient!"
      [Constant, Entry, Api].map { |klass| klass.delete_all }
      
      update_api!("Rails", "http://api.rubyonrails.org")
      update_api!("Ruby 1.8.7", "http://www.ruby-doc.org/core")
      update_api!("Ruby 1.9", "http://ruby-doc.org/ruby-1.9")
      
    end
    
    def update_api!(name, url)
      puts "Updating API for #{name}..."
      api = Api.find_or_create_by_name_and_url(name, url)
      api.update_methods!
      api.update_classes!
      puts "DONE (with #{name})!"
    end
   
    def find_constant(name, entry=nil)
      # Find by specific name.
      constants = Constant.find_all_by_name(name, :include => "entries")
      # search for class methods, which is prolly what we want if we can find it
      constants = Constant.find_all_by_name("#{name}::ClassMethods", :include => "entries") if constants.empty?
      # Find by name beginning with <blah>.
      constants = Constant.all(:conditions => ["name LIKE ?", name + "%"], :include => "entries") if constants.empty?
      # Find by fuzzy.
      match="%#{name.split("").join("%")}%"
      constants = Constant.find_by_sql("select * from constants where name LIKE '#{match}'") if constants.empty?
      regex=build_regex_from_constant(name)
      constants = constants.select { |x| x.name =~ regex }
      # Narrow it down to the constants that only contain the entry we are looking for.
      if entry
        constants = constants.select { |constant| !constant.entries.find_by_name(entry).nil? }
      end
      constants
    end
     
    # this uses a regex to lock down our SQL finds even more
    # so that things like AR::Base will not match
    # ActiveRecord::ConnectionAdapters::DatabaseStatements 
    def build_regex_from_constant(name)
      parts=name.split("::").map do |c|
        c.split("").join("[^:]*")+"[^:]*"
      end
      /#{parts.join("::")}/i
    end
    
    def smart_rails_constant_substitutions(name)
      parts = name.split("::").map { |x| x.split(":")}.flatten
      if parts.first
        rep = case parts.first.downcase
          # so it falls back on fuzzy and matches AR as well as ActiveResource
          when "ar" then "ActiveRecord" 
          when "ares" then "ActiveResource" 
          when "am" then "ActionMailer"
          when "as" then "ActiveSupport"
          when "ac" then "ActionController"
          when "av" then "ActionView"
          else 
            parts.first
        end
        return ([rep] + parts[1..-1]).join("::")
      end
      name
    end
    
    # Find an entry.
    # If the constant argument is passed, look it up within the scope of the constant.
    def find_method(name, constant=nil)
      methods = []
      # Full match
      methods = Entry.find_all_by_name(name.to_s)
      # Start match
      methods = Entry.all(:conditions => ["name LIKE ?", name.to_s + "%"]) if methods.empty?
      # Wildcard substitution
      methods = Entry.find_by_sql("select * from entries where name LIKE '#{name.to_s.gsub("*", "%")}'") if methods.empty?
      # Fuzzy match
      methods = Entry.find_by_sql("select * from entries where name LIKE '%#{name.to_s.split("").join("%")}%'") if methods.empty?
      
      # Weight the results, last result is the first one we want shown first
      methods = methods.sort_by(&:weighting)
    
      if constant
        constants = find_constant(constant)
        methods = methods.select { |m| constants.include?(m.constant) }
      end
      methods
    end
          
    def search(msg, options={})
      options[:api] ||= if /^1\.9/.match(msg)
        "Ruby 1.9"
      elsif /^1\.8/.match(msg)
        "Ruby 1.8.7"
      elsif /^Rails/i.match(msg)
        "Rails"
      end
      
      msg = msg.gsub(/^(.*?)\s/, "") if options[:api]
      
      splitter = options[:splitter] || "#"
      parts = msg.split(" ")[0..-1].flatten.map { |a| a.split(splitter) }.flatten!
      # It's a constant! Oh... and there's nothing else in the string!
      first = smart_rails_constant_substitutions(parts.first)
      output = if /^[A-Z]/.match(first) && parts.size == 1
        find_constant(first)
       # It's a method!
      else
        # Right, so they only specified one argument. Therefore, we look everywhere.
        if parts.size == 1
          o = find_method(parts.last)
        # Left, so they specified two arguments. First is probably a constant, so let's find that!
        else
          o = find_method(parts.last, first)
        end
        o
      end

      output = search(msg, options.merge(:splitter => ".")) if output.empty? && splitter != "."
      
      options[:api] ||= ["Ruby 1.8.7", "Rails"]
      selected_output = output.select { |m| options[:api].include?(m.api.name) }
      selected_output = output if selected_output.empty?

      return selected_output
    end
     
  end
end


require File.join(File.dirname(__FILE__), 'models')