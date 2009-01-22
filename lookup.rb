require 'config'

def update
  puts "UPDATING..."
  Constant.delete_all
  Entry.delete_all

  doc = Hpricot(Net::HTTP.get(URI.parse("http://api.rubyonrails.org/fr_class_index.html")))
  doc.search("a").each do |a|
    Constant.find_or_create_by_name_and_url(a.inner_html, "http://api.rubyonrails.org/" + a["href"]) 
  end


  doc = Hpricot(Net::HTTP.get(URI.parse("http://api.rubyonrails.org/fr_method_index.html")))
  doc.search("a").each do |a|
    names = a.inner_html.split(" ")
    method = names[0]
    name = names[1].gsub(/[\(|\)]/, "")
    # The same constant can be defined twice in different APIs, be wary!
    url = "http://api.rubyonrails.org/classes/" + name.gsub("::", "/") + ".html"
    constant = Constant.find_or_create_by_name_and_url(name, url)
    constant.entries.create!(:name => method, :url => "http://api.rubyonrails.org/" + a["href"])
  end
end
 
ActiveRecord::Base.logger = Logger.new("lookup.log") if DEBUG

def find_constant(name, entry=nil)
  # Find by specific name.
  constants = Constant.find_all_by_name(name)
  # Find by name beginning with <blah>.
  constants = Constant.all({:conditions => ["name LIKE ?", "#{name}%"]}) if constants.empty?
  # Find by name containing letters of <blah> in order.
  constants = Constant.all({:conditions => ["name LIKE ?", "%#{name.split("").join("%")}%"]}) if constants.empty?
  if constants.size > 1
    # Narrow it down to the constants that only contain the entry we are looking for.
     constants = constants.select { |c| c.entries.map(&:name).include?(entry) } if !entry.nil?
     if constants.size > 1 
       puts "More than one constant matched your search! 5 most likely (based on times referenced): #{constants.first(5).map(&:name).to_sentence}"
     elsif constants.size == 1
       return constants.first
     else
       if entry
         puts "There are no constants that match #{name} and contain #{entry}."
       else
         puts "There are no constants that match #{name}"
       end
     end
  else
    return constants.first
  end
end
 
 # Find an entry.
 # If the constant argument is passed, look it up within the scope of the constant.
 def find_entry(name, constant=nil)  
   # So constant can be either a constant object, OR a string.
   if constant.class == String
     constant = find_constant(constant, name)
   end
  
   # Set the scope of the find.
   # Props to universa1
   scope = constant ? constant.entries : Entry
   
   # Find it within the scope of whatever.
   entries = scope.find_all_by_name(name)
   # Find methods beginning with <blah>.
   entries = scope.all(:conditions => ["name LIKE ?", "#{name}%"]) if entries.empty?
   # Find methods containing letters of <blah> in order.
   entries = scope.all(:conditions => ["name LIKE ?", "%" + name.split("").join("%") + "%"]) if entries.empty?
   if entries.size == 2 && !(duplicate_entries = entries.group_by {|s| s.with_constant}.collect{|s|s[1]}.select { |a| a.size > 1 }).empty?
     # Did we find the same constant AND the same entry?
     # Just output both!
     return entries
   elsif entries.size >= 2
      puts "More than one method matched your search! 5 most likely (based on times referenced): #{entries.first(5).map(&:with_constant).to_sentence}"
   else
     return entries.first
   end
 end
   
 
 def lookup
   # ActiveRecord
   # ActiveRecord::Base
   # ActiveRecord Base destroy
   # destroy
   # ActiveRec
   parts = ARGV[0..-1].map { |a| a.split("#") }.flatten!
   
   # It's a constant! Oh... and there's nothing else in the string!
   if /^[A-Z]/.match(parts.first) && parts.size == 1
    object = find_constant(parts.first)
    # It's a method!
    else
      # Right, so they only specified one argument. Therefore, we look everywhere.
      if parts.first == parts.last
        object = find_entry(parts.first)
      # Left, so they specified two arguments. First is probably a constant, so let's find that!
      else
        object = find_entry(parts.last, parts.first)
      end  
   end 
   puts object
 end
 # update
 lookup