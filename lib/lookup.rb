require 'rubygems'
require 'activerecord'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => File.join(File.dirname(__FILE__), "lookup.sqlite3"))
class APILookup

  class << self
    def update
      require 'hpricot'
      require 'net/http'
      puts "Updating API, this may take a minute or two. Please be patient!"
      Constant.delete_all
      Entry.delete_all
      # Ruby on Rails Classes & Methods
      update_api("Rails", "http://api.rubyonrails.org")
      # Ruby Classes & Methods
      update_api("Ruby", "http://www.ruby-doc.org/core")
      
      weight_results
      puts "Updated API index! Use the lookup <method> or lookup <class> <method> to find what you're after"
    end
  
    def update_api(name, url)
      puts "Updating API for #{name}"
      Api.find_or_create_by_name_and_url(name, url)
      update_methods(Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_method_index.html"))), url)
      update_classes(Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_class_index.html"))), url)
      puts "Updated API for #{name}!"
    end
  
    def update_methods(doc, prefix)
      doc.search("a").each do |a|
        names = a.inner_html.split(" ")
        method = names[0]
        name = names[1].gsub(/[\(|\)]/, "")
        # The same constant can be defined twice in different APIs, be wary!
        url = prefix + "/classes/" + name.gsub("::", "/") + ".html"
        constant = Constant.find_or_create_by_name_and_url(name, url)
        constant.entries.create!(:name => method, :url => prefix + "/" + a["href"])
      end
    end
  
    def update_classes(doc, prefix)
      doc.search("a").each do |a|
        constant = Constant.find_or_create_by_name_and_url(a.inner_html, prefix + "/" + a["href"])
      end
    end
    
    # Weights the results so the ones more likely to be used by people come up first.
    def weight_results
      e = Constant.find_by_name("ActiveRecord::Associations::ClassMethods").entries.find_by_name("belongs_to")
      e.increment!(:weighting)
    end
  
    def find_constant(name, entry=nil)
      # Find by specific name.
      constants = Constant.find_all_by_name(name, :include => "entries")
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
      return /.*/
      parts=name.split("::").map do |c|
        c.split("").join("[^:]*")+"[^:]*"
      end
      /#{parts.join("::")}/i
    end
    
    def smart_rails_constant_substitutions(name)
      parts=name.split("::")
      rep = case parts.first.downcase
        # so it falls back on fuzzy and matches AR as well as ActiveResource
        when "ar": "ActiveRe" 
        when "am": "ActionMailer"
        when "as": "ActiveSupport"
        when "ac": "ActionController"
        when "av": "ActionView"
        else 
          parts.first
      end
      ([rep] + parts[1..-1]).join("::")
    end
  
    # Find an entry.
    # If the constant argument is passed, look it up within the scope of the constant.
    def find_method(name, constant=nil)
      methods = []
      methods = Entry.find_all_by_name(name.to_s)
      methods = Entry.all(:conditions => ["name LIKE ?", name.to_s + "%"]) if methods.empty?
      methods = Entry.find_by_sql("select * from entries where name LIKE '%#{name.split("").join("%")}%'") if methods.empty?
      
      # Weight the results, last result is the first one we want shown first
      methods = methods.sort_by(&:weighting)
    
      if constant
        constants = find_constant(constant, name)
        methods = methods.select { |m| constants.include?(m.constant) }
      end
      methods      
    end
          
    def search(msg)
      msg = msg.split(" ")[0..-1].flatten.map { |a| a.split("#") }.flatten!
    
      # It's a constant! Oh... and there's nothing else in the string!
      first=smart_rails_constant_substitutions(msg.first)
      if /^[A-Z]/.match(first) && msg.size == 1
       find_constant(first)
       # It's a method!
      else
        # Right, so they only specified one argument. Therefore, we look everywhere.
        if msg.size == 1
          find_method(msg)
        # Left, so they specified two arguments. First is probably a constant, so let's find that!
        else
          find_method(msg.last, first)
        end  
      end
    end
    
  end
end

require File.join(File.dirname(__FILE__), 'models')
