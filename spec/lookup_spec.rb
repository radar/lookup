require File.dirname(__FILE__) + '/spec_helper'

describe "Lookup" do
  before(:all) do
   # Lookup.update!
  end
  
  def find_api(name)
    Lookup::Api.find_by_name(name)
  end
  
  def find_constant(api, name)
    find_api(api).constants.find_by_name(name)
  end
  
  def find_entry(api, constant, name)
    find_constant(api, constant).entries.find_all_by_name(name)
  end
  
  def search(term, options={})
    Lookup.search(term, options)
  end
  
  it "should be able to find a method in Ruby 1.9" do
    search("1.9 shuffle").should eql(find_entry("Ruby 1.9", "Array", "shuffle"))
  end
  
  it "should be able to lookup for Ruby 1.9 only" do
    search("1.9 Array#flatten").should eql(find_entry("Ruby 1.9", "Array", "flatten"))
  end
  
  it "should lookup for 1.8" do
    search("1.8 Array#flatten").should eql(find_entry("Ruby 1.8", "Array", "flatten"))
  end
  
  it "should lookup for the current version of Ruby" do
    case RUBY_VERSION
      when /^1.8/
        search("Array#flatten").should eql(find_entry("Ruby 1.8", "Array", "flatten"))
      when /^1.9/
        search("Array#flatten").should eql(find_entry("Ruby 1.9", "Array", "flatten"))
      end
  end
  
  it "should be able to find a constant" do
    search("v2.3.8 ActiveRecord::Base").should eql([find_constant("Rails v2.3.8", "ActiveRecord::Base")])
  end
  
  it "should be able to find a short constant" do
    search("v2.3.8 ar::Base").should eql([find_constant("Rails v2.3.8", "ActiveRecord::Base")])
  end
  
  it "should be able to find a constant and a method (using hash symbol)" do
    search("v2.3.8 ActiveRecord::Base#new").should eql(find_entry("Rails v2.3.8", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find a constant and a method (using spaces)" do
    search("v2.3.8 ActiveRecord::Base new").should eql(find_entry("Rails v2.3.8", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find a constant and a method (specified wildcard)" do
    search("v2.3.8 ActiveRecord::Base#n*w").should eql(find_entry("Rails v2.3.8", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find a constant and some methods (fuzzy)" do
    search("v2.3.8 ActiveRecord::Base#nw").should eql([find_entry("Rails v2.3.8", "ActiveRecord::Base", "new"), find_entry("Rails v2.3.8", "ActiveRecord::Base", "new_record?")].flatten)
  end
  
  it "should be able to find the constant and method by code examples" do
    search("v2.3.8 ActiveRecord::Base.destroy").should eql(find_entry("Rails v2.3.8", "ActiveRecord::Base", "destroy"))
  end
  
  it "should be able to search on shortened constants" do
    search("v2.3.8 ar::base#new").should eql(find_entry("Rails v2.3.8", "ActiveRecord::Base", "new"))
  end
  
  it "Should be able to find a Rails 3 constant" do
    search("v3.0.0 Rails::Engine").should eql([find_constant("Rails v3.0.0", "Rails::Engine")])
  end
  
  it "should be able to find it if a hash-symbol is specified" do
    # sort_by used here because once it returned it out of order.
    # Ensure order.
    Lookup.search("v2.3.8 #today?").should eql([ find_entry("Rails v2.3.8", "ActiveSupport::CoreExtensions::Date::Calculations", "today?"),
                                             find_entry("Rails v2.3.8", "ActiveSupport::TimeWithZone", "today?"),
                                             find_entry("Rails v2.3.8", "ActiveSupport::CoreExtensions::Time::Calculations", "today?")
                                           ].flatten!.sort_by(&:id))
  end
  
end
