#!/usr/bin/ruby
LIB_DIR = File.dirname(__FILE__)

CLASSES = File.join(LIB_DIR, "classes")
METHODS = File.join(LIB_DIR, "methods")
DECENT_OPERATING_SYSTEM = RUBY_PLATFORM =~ /darwin/

require File.join(LIB_DIR, "config")

# Updates blazingly fast now.
def update
  puts "UPDATING..."
  f = File.open(CLASSES, "w+")
  f.close
  f = File.open(METHODS, "w+")
  f.close
  update_api("http://api.rubyonrails.org/")
  update_api("http://ruby-doc.org/core/")
end

def update_api(url)
  update_classes(url)
  update_methods(url)
end

def update_classes(url)
  c = File.open(CLASSES,"a+")
  classes = File.readlines(CLASSES)
  doc = Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_class_index.html")))
  doc.search("a").each do |a|
    puts "#{a.inner_html}"
    c.write "#{a.inner_html} #{url + a['href']}\n" if !classes.include?(a.inner_html)
  end
end

def update_methods(url)
  c = File.open(CLASSES, "a+")
  classes = File.readlines(CLASSES)
  e = File.open(METHODS, "a+")
  methods = File.readlines(METHODS)
  doc = Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_method_index.html")))
  doc.search("a").each do |a|
    constant_name = a.inner_html.split(" ")[1].gsub(/[\(|\)]/, "")
    if /^[A-Z]/.match(constant_name)
      e.write "#{a.inner_html} #{url + a['href']}\n"
    end
  end
end

def display_constants(constants)
  x = 0
  if constants.size < 10
    puts "Found #{constants.size} result(s):" unless DECENT_OPERATING_SYSTEM
    for constant in constants
      if DECENT_OPERATING_SYSTEM
        `open #{constant.last}`
      else
        puts "#{x += 1}. #{constant.first} #{constant.last}"
      end
    end
  else
    puts "Please refine your query, we found #{constants.size} constants."
  end
  [constants, constants.size]
end

def find_constant(name, entry=nil)
  # Find by specific name.
  constants = @classes.select { |c| c.first == name }
  # Find by name beginning with <blah>.
  constants = @classes.select { |c| /^#{name}.*/.match(c.first) } if constants.empty?  
  # Find by name containing letters of <blah> in order.
  constants = @classes.select { |c| Regexp.new(name.split("").join(".*")).match(c.first) }
  if constants.size > 1
    # Narrow it down to the constants that only contain the entry we are looking for.
    constants = constants.select { |constant| @methods.select { |m| m.first == entry && /#{entry} (#{constant.first})/.match([m.first, m[1]].join(" ")) } } if !entry.nil?
    display_constants(constants)
    if constants.size == 1
      return [[constants.first], 1]
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
   methods = @methods.select { |m| m.first == name}
   methods = @methods.select { |m| /#{name}.*/.match(m.first) } if methods.empty?
   methods = @methods.select { |m| Regexp.new(name.split("").join(".*")).match(m.first) } if methods.empty?   
   if constant
     methods = methods.select { |m| /#{constants.join("|")}/.match(m[1]) }
   end
   x = 0
   if methods.size < 10
     puts "Found #{methods.size} result(s):" unless DECENT_OPERATING_SYSTEM
     for method in methods
       if DECENT_OPERATING_SYSTEM
         `open #{method.last}`
       else
         puts "#{x += 1}. #{method[1].gsub(/[\(|\)]/, '')}##{method.first} #{method.last}"
       end
     end
   else
     puts "Please refine your query, we found #{methods.size} methods."
   end
   methods
 end
   
 
 def lookup
   @classes = File.readlines(CLASSES).map { |line| line.split(" ")}
   @methods = File.readlines(METHODS).map { |line| line.split(" ")}
   parts = ARGV[0..-1].map { |a| a.split("#") }.flatten!
   
   # It's a constant! Oh... and there's nothing else in the string!
   if /^[A-Z]/.match(parts.first) && parts.size == 1
    object = find_constant(parts.first)
    # It's a method!
    else
      # Right, so they only specified one argument. Therefore, we look everywhere.
      if parts.first == parts.last
        object = find_method(parts.first)
      # Left, so they specified two arguments. First is probably a constant, so let's find that!
      else
        object = find_method(parts.last, parts.first)
      end  
   end
   object
 end
 lookup