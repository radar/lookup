require 'net/http'
require 'fileutils'

require 'active_record'
require 'nokogiri'


# Because some of you don't have ActiveSupport 3.0
# And I'm too lazy to require all the shit for 2.3.8 just for this.
class Hash
  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end
end

module Lookup
  APIS = []
  
  class APINotFound < Exception; end

  class << self
    
    def home
      Pathname.new(ENV["HOME"]) + ".lookup"
    end
    
    def config
      YAML.load_file(home + "config")
    end
      
    def apis
      apis = config["apis"].stringify_keys!
    end
    
    def update!
      FileUtils.mkdir_p(home)
      if !File.exists?(home + "config")
        FileUtils.cp(File.dirname(__FILE__) + "/../config/lookup", home + "config")
      end
      
      puts "Updating API, this may take a minute or two. Please be patient!"
      [Constant, Entry, Api].map { |klass| klass.delete_all }
      puts "Updating #{apis.size} APIs."
      for api in apis.values
        update_api!(api["name"], api["url"])
      end
    end
    
    def update_api!(name, url)
      puts "Updating API for #{name}..."
      api = Api.find_or_create_by_name_and_url(name, url)
      APIS << api
      puts "Updating methods for #{name}"
      api.update_methods!
      puts "Updating classes for #{name}"
      api.update_classes!
      puts "The #{name} API is done."
    end
   
    def find_constant(name, entry=nil, options={})
      scope = options[:api].constants || Constant
      # Find by specific name.
      constants = scope.find_all_by_name(name, :include => "entries")
      # search for class methods, which is prolly what we want if we can find it
      constants = scope.find_all_by_name("#{name}::ClassMethods", :include => "entries") if constants.empty?
      # Find by name beginning with <blah>.
      constants = scope.all(:conditions => ["constants.name LIKE ?", name + "%"], :include => "entries") if constants.empty?
      # Find by fuzzy.
      match="%#{name.split("").join("%")}%"
      constants = scope.find_by_sql("select * from constants where name LIKE '#{match}'") if constants.empty?
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
    def find_method(name, constant=nil, options = {})
      scope = options[:api].entries || Entry
      methods = []
      # Full match
      methods = scope.find_all_by_name(name.to_s)
      # Start match
      methods = scope.all(:conditions => ["entries.name LIKE ?", name.to_s + "%"]) if methods.empty?
      # Wildcard substitution
      methods = scope.find_by_sql("select * from entries where name LIKE '#{name.to_s.gsub("*", "%")}'") if methods.empty?
      # Fuzzy match
      methods = scope.find_by_sql("select * from entries where name LIKE '%#{name.to_s.split("").join("%")}%'") if methods.empty?
      
      # Weight the results, last result is the first one we want shown first
      methods = methods.sort_by(&:weighting)
    
      if constant
        constants = find_constant(constant, nil, options)
        methods = methods.select { |m| constants.include?(m.constant) }
      end
      methods
    end
          
    def search(msg, options={})
      first_word = msg.split.first
      options[:api] ||= first_word if apis.keys.include?(first_word)
      api_check = lambda { |options| (!apis.keys.map(&:to_s).include?(options[:api]) && !options[:api].is_a?(Api)) }
      # to_s because yaml interprets "1.8" as a literal 1.8
      # And because I'm super, super lazy
      if api_check.call(options)
        # Attempt a current Ruby lookup
        api = case RUBY_VERSION
          when /^1.8/
            "1.8"
          when /^1.9/
            "1.9"
        end
        search(msg, options.merge!(:api => api)) if api 
      end
      
      options[:api] = Api.find_by_name!(apis[options[:api]]["name"]) if (options[:api] && apis[options[:api]].try(:[], "name")) && !options[:api].is_a?(Api)
      
      raise Lookup::APINotFound, "Could not determine what API the lookup is for" unless options[:api]
      
      # We want to retain message.
      msg = msg.gsub(/^(.*?)\s/, "")
      
      splitter = options[:splitter] || "#"
      parts = msg.split(" ")[0..-1].flatten.map { |a| a.split(splitter) }.flatten!
      # It's a constant! Oh... and there's nothing else in the string!
      first = smart_rails_constant_substitutions(parts.first)
      
      output = if /^[A-Z]/.match(first) && parts.size == 1
        find_constant(first, nil, options)
       # It's a method!
      else
        # Right, so they only specified one argument. Therefore, we look everywhere.
        if parts.size == 1
          o = find_method(parts.last, nil, options)
        # Left, so they specified two arguments. First is probably a constant, so let's find that!
        else
          o = find_method(parts.last, first, options)
        end
        o
      end

      output = search(msg, options.merge(:splitter => ".")) if output.empty? && splitter != "."
      selected_output = output.select { |m| options[:api].name == m.api.name }
      selected_output = output if selected_output.empty?

      return selected_output
    end

    private
     
    def api_not_found
      raise Lookup::APINotFound, %Q{You must specify a valid API as the first keyword. Included APIs:\n} +
          (apis.map do |short, info|
            "#{short} - #{info["name"]}"
          end.join("\n"))

    end
  end
end

require File.expand_path('../lookup/models', __FILE__)
