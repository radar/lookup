require File.dirname(__FILE__) + '/spec_helper'

describe "Lookup" do
  
  def find_api(name)
    APILookup::Api.find_by_name(name)
  end
  
  def find_constant(api, name)
    find_api(api).constants.find_by_name(name)
  end
  
  def find_entry(api, constant, name)
    find_constant(api, constant).entries.find_all_by_name(name)
  end
  
  def search(term, options={})
    APILookup.search(term, options)
  end
  
  it "should be able to find a method in Ruby 1.9" do
    search("shuffle").should eql(find_entry("Ruby 1.9", "Array", "shuffle"))
  end
  
  it "should be able to lookup for Ruby 1.9 only" do
    search("1.9 Array#flatten").should eql(find_entry("Ruby 1.9", "Array", "flatten"))
  end
  
  it "should lookup for 1.8 and Rails if no API specified" do
    search("Array#flatten").should eql(find_entry("Ruby 1.8.7", "Array", "flatten"))
  end
  
  it "should lookup for 1.8" do
    search("1.8 Array#flatten").should eql(find_entry("Ruby 1.8.7", "Array", "flatten"))
  end
  
  it "should be able to find a constant" do
    search("ActiveRecord::Base").should eql([find_constant("Rails", "ActiveRecord::Base")])
  end
  
  it "should be able to find a short constant" do
    search("ar::Base").should eql([find_constant("Rails", "ActiveRecord::Base")])
  end
  
  it "should be able to find a constant and a method (using hash symbol)" do
    search("ActiveRecord::Base#new").should eql(find_entry("Rails", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find a constant and a method (using spaces)" do
    search("ActiveRecord::Base new").should eql(find_entry("Rails", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find a constant and a method (specified wildcard)" do
    search("ActiveRecord::Base#n*w").should eql(find_entry("Rails", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find a constant and some methods (fuzzy)" do
    search("ActiveRecord::Base#nw").should eql([find_entry("Rails", "ActiveRecord::Base", "new"), find_entry("Rails", "ActiveRecord::Base", "new_record?")].flatten)
  end
  
  it "should be able to find the constant and method by code examples" do
    search("ActiveRecord::Base.destroy").should eql(find_entry("Rails", "ActiveRecord::Base", "destroy"))
  end
  
  it "should be able to search on shortened constants" do
    search("ar::base#new").should eql(find_entry("Rails", "ActiveRecord::Base", "new"))
  end
  
  it "should be able to find it if a hash-symbol is specified" do
    # sort_by used here because once it returned it out of order.
    # Ensure order.
    APILookup.search("#today?").should eql([ find_entry("Rails", "ActiveSupport::CoreExtensions::Date::Calculations", "today?"),
                                             find_entry("Rails", "ActiveSupport::TimeWithZone", "today?"),
                                             find_entry("Rails", "ActiveSupport::CoreExtensions::Time::Calculations", "today?")
                                           ].flatten!.sort_by(&:id))
  end
  
end
