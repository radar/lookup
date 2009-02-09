#!/usr/bin/ruby
require 'fileutils'
LIB_DIR = File.dirname(__FILE__)
DECENT_OPERATING_SYSTEM = RUBY_PLATFORM =~ /darwin/
GEM_SERVER = "http://localhost:8808"
DOC_PATH = File.join(LIB_DIR, "../doc")
require File.join(LIB_DIR, "config")
# Updates blazingly fast now.

def update
  system("gem server")
  home_page = Hpricot(Net::HTTP.get(URI.parse(GEM_SERVER)))
  home_page.search("a").select { |a| a.inner_html == "[rdoc]"}.each do |a|
    href = a['href'].gsub(/\/index.html/, '')
    url = "#{GEM_SERVER}#{href}/"
    @gem_name = url.split("/")[4]
    @classes_file = File.join(LIB_DIR, "..", 'doc', "#{@gem_name}-classes")
    @methods_file = File.join(LIB_DIR, "..", 'doc', "#{@gem_name}-methods")
    update_classes(url) unless File.exist?(@classes_file)
    update_methods(url) unless File.exist?(@methods_file)
  end
  @classes_file = File.join(LIB_DIR, "..", 'doc', "ruby-classes")
  @methods_file = File.join(LIB_DIR, "..", 'doc', "ruby-methods")
  update_classes("http://ruby-doc.org/core/") unless File.exist?(@classes_file)
  update_methods("http://ruby-doc.org/core/") unless File.exist?(@methods_file)
end

def update_classes(url)
  c = File.open(@classes_file, "w")
  classes = File.readlines(@classes_file)
  doc = Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_class_index.html")))
  doc.search("a").each do |a|
    c.write "#{a.inner_html} #{url + a['href']}\n" if !classes.include?(a.inner_html)
  end
  c.close
end

def update_methods(url)
  m = File.open(@methods_file, "w")
  doc = Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_method_index.html")))
  doc.search("a").each do |a|
    constant_name = a.inner_html.split(" ")[1].gsub(/[\(|\)]/, "")
    if /^[A-Z]/.match(constant_name)
      m.write "#{a.inner_html} #{url + a['href']}\n"
    end
  end
  m.close
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
  @classes = @classes.flatten.map { |m| m.split(" ") }
  # Find by specific name.
  constants = @classes.select { |c| c.first == name }
  # Find by name beginning with <blah>.
  constants = @classes.select { |c| Regexp.new("^#{name}.*").match(c.first) } if constants.empty?
  # Find by name containing letters of <blah> in order.
  constants = @classes.select { |c| Regexp.new(name.split("").join(".*")).match(c.first).nil? } if constants.empty?
  # puts constants.inspect
  if constants.size > 1
    # Narrow it down to the constants that only contain the entry we are looking for.
    constants = constants.select { |constant| @methods.select { |m| m.first == entry && /#{entry} (#{constant.first})/.match([m.first, m[1]].join(" ")) } } if !entry.nil?
    if constants.size == 1
      return [[constants.first], 1]
    elsif constants.size == 0
      if entry
        puts "There are no constants that match #{name} and contain #{entry}."
      else
        puts "There are no constants that match #{name}"
      end
    else
      if entry.nil?
        display_constants(constants)
      else
        return [constants, constants.size]
      end
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
  @methods = @methods.flatten.map { |m| m.split(" ") }
 if constant
   constants, number = find_constant(constant, name)
 end
 methods = []
 methods = @methods.select { |m| m.first == name }
 methods = @methods.select { |m| Regexp.new("^#{name}.*").match(m.first) } if methods.empty?
 methods = @methods.select { |m| Regexp.new(name.split("").join(".*")).match(m.first) } if methods.empty?   
 if constant
   methods = methods.select { |m| /#{constants.map { |c| c.first }.join("|")}/.match(m[1]) }
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
  load_files(ARGV[0])
  parts = ARGV[1..-1].map { |a| a.split("#") }.flatten!

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

def load_files(name)
  @classes = []
  @methods = []
  case name
  when "rails"
    # Require all the rails related gems.
    # We require the ruby docs here because some people have been known to get confused.
    gems = ["actionmailer", "actionpack", "activerecord", "activeresource", "activesupport", "rake"].map { |e| "e*" } + ["ruby"]
    load_gems(gems)
  when "ruby"
    gems = ["ruby"]
    load_gems(gems)
  else
    load_gems([name])
  end

end

def load_gems(gems)
  for gem in gems
    classes = Dir["#{DOC_PATH}/#{gem}-classes"].sort
    methods = Dir["#{DOC_PATH}/#{gem}-methods"].sort
    @classes << File.readlines(classes.last).flatten unless classes.empty?
    @methods << File.readlines(methods.last).flatten unless methods.empty?
  end
end

begin
  update
  lookup
end