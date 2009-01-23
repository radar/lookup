require 'config'

# Updates blazingly fast now.
def update
  puts "UPDATING..."
  f = File.open("classes", "w+")
  f.close
  f = File.open("methods", "w+")
  f.close
  update_api("http://api.rubyonrails.org/")
  update_api("http://ruby-doc.org/core/")
end

def update_api(url)
  update_classes(url)
  update_methods(url)
end

def update_classes(url)
  c = File.open("classes","a+")
  classes = File.readlines("classes")
  doc = Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_class_index.html")))
  doc.search("a").each do |a|
    puts "#{a.inner_html}"
    c.write "#{a.inner_html} #{url + a['href']}\n" if !classes.include?(a.inner_html)
  end
end

def update_methods(url)
  c = File.open("classes", "a+")
  classes = File.readlines("classes")
  e = File.open("methods", "a+")
  methods = File.readlines("methods")
  doc = Hpricot(Net::HTTP.get(URI.parse("#{url}/fr_method_index.html")))
  doc.search("a").each do |a|
    constant_name = a.inner_html.split(" ")[1].gsub(/[\(|\)]/, "")
    if /^[A-Z]/.match(constant_name)
      e.write "#{a.inner_html} #{url + a['href']}\n"
    end
  end
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
       constants = @classes.select { |constant| @methods.select { |m| /#{entry}/.match(m.first) && m[1] == "(#{constant})" } } if !entry.nil?
       if constants.size > 1 
         puts "More than one constant matched your search! 5 most likely (based on times referenced): #{constants.first(5).map(&:first).to_sentence}"
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
    if entry.nil?
      x = 0
      puts "Found #{constants.size} result(s):"
      for constant in constants
        puts "#{x += 1}. #{constant.first} #{constant.last}"
      end
    else
      constants.first
    end
  end
end
 
 # Find an entry.
 # If the constant argument is passed, look it up within the scope of the constant.
 def find_method(name, constant=nil)  
   if constant
     constant = find_constant(constant, name)
   end
   methods = @methods.select { |m| m.first == name}
   methods = @methods.select { |m| /#{name}.*/.match(m.first) } if methods.empty?
   methods = @methods.select { |m| Regexp.new(name.split("").join(".*")).match(m.first) } if methods.empty?   
   methods = methods.select { |m| m[1] == "(#{constant.first})" } if constant
   x = 0
   puts "Found #{methods.size} result(s):"
   for method in methods
     puts "#{x += 1}. #{constant.nil? ? method[1].gsub(/[\(|\)]/, '') : constant.first}##{method.first} #{method.last}"
   end
 end
   
 
 def lookup
   @classes = File.readlines("classes").map { |line| line.split(" ")}
   @methods = File.readlines("methods").map { |line| line.split(" ")}
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
 end
 update if !File.exist?("classes") || !File.exist?("methods")
 lookup