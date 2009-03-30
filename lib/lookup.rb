require 'rubygems'
require 'activerecord'

MAC = !!/darwin/.match(PLATFORM)
WINDOWS = !!/win/.match(PLATFORM)


# How many methods / constants to return.
THRESHOLD = 5

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
      constants = Constant.find_by_sql("select * from constants where name LIKE '%#{name.split("").join("%")}%'") if constants.empty?
      if constants.size > 1
        # Narrow it down to the constants that only contain the entry we are looking for.
        if !entry.nil?
          constants = constants.select { |constant| !constant.entries.find_by_name(entry).nil? }
          return [constants, constants.size]
        else
          display_constants(constants)
        end
        if constants.size == 1
          if entry.nil?
            display_constants(constants)
          else
            return [[constants.first], 1]
          end
        elsif constants.size == 0
          if entry
            puts "There are no constants that match #{name} and contain #{entry}."
          else
            puts "There are no constants that match #{name}"
          end
        else
          return [constants, constants.size]
        end
      else
        if entry.nil?
         display_constants(constants)
        else
          return [[constants.first], 1]
        end
      end
    end  
  
    # Find an entry.
    # If the constant argument is passed, look it up within the scope of the constant.
    def find_method(name, constant=nil)
      if constant
        constants, number = find_constant(constant, name)
      end
      methods = [] 
      methods = Entry.find_all_by_name(name.to_s)
      methods = Entry.all(:conditions => ["name LIKE ?", name.to_s + "%"]) if methods.empty?
      methods = Entry.find_by_sql("select * from entries where name LIKE '%#{name.split("").join("%")}%'") if methods.empty?
      
      # Weight the results, last result is the first one we want shown first
      methods = methods.sort_by(&:weighting)
    
      if constant
        methods = methods.select { |m| constants.include?(m.constant) }
      end
      count = 0
      if methods.size == 1
        method = methods.first
        if OPTIONS[:text]
          puts display_method(method)
        elsif MAC
          `open #{method.url}`
        elsif WINDOWS
          `start #{method.url}`
        else
          puts display_method(method)
        end
      elsif methods.size <= THRESHOLD
        for method in methods
          if OPTIONS[:text]
            puts "#{count += 1}. #{display_method(method)}"
          elsif MAC
            `open #{method.url}`
          elsif WINDOWS 
            `start #{method.url}`
          else
            puts "#{count += 1}. #{display_method(method)}"
          end
        end
        methods
      else
        puts "Please refine your query, we found #{methods.size} methods. Threshold is #{THRESHOLD}."
      end
      return nil
    end
    
    def display_method(method)
      "(#{method.constant.name}) #{method.name} #{method.url}"
    end
      
    def do(msg)
      msg = msg.split(" ")[0..-1].flatten.map { |a| a.split("#") }.flatten!
    
      # It's a constant! Oh... and there's nothing else in the string!
      if /^[A-Z]/.match(msg.first) && msg.size == 1
       object = find_constant(msg.first)
       # It's a method!
      else
        # Right, so they only specified one argument. Therefore, we look everywhere.
        if msg.first == msg.last
          object = find_method(msg)
        # Left, so they specified two arguments. First is probably a constant, so let's find that!
        else
          object = find_method(msg.last, msg.first)
        end  
      end
    end
    
  end
end

require File.join(File.dirname(__FILE__), 'models')
