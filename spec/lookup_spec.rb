require File.dirname(__FILE__) + '/spec_helper'

describe "Lookup" do
  
  def find_constant(name)
    APILookup::Constant.find_by_name(name)
  end
  
  def find_entry(constant, name)
    APILookup::Entry.find_by_name_and_constant_id(name, find_constant(constant).id)
  end
  
  before do
  end
  
  it "should be able to find a constant" do
    APILookup.search("ActiveRecord::Base").should eql([find_constant("ActiveRecord::Base")])
  end
  
  it "should be able to find a short constant" do
    APILookup.search("ar::Base").should eql([find_constant("ActiveRecord::Base")])
  end
  
  it "should be able to find a constant and a method (using hash symbol)" do
    APILookup.search("ActiveRecord::Base#new").should eql([find_entry("ActiveRecord::Base", "new")])
  end
  
  it "should be able to find a constant and a method (using spaces)" do
     APILookup.search("ActiveRecord::Base new").should eql([find_entry("ActiveRecord::Base", "new")])
   end
  
  it "should be able to find a constant and a method (specified wildcard)" do
     APILookup.search("ActiveRecord::Base#n*w").should eql([find_entry("ActiveRecord::Base", "new")])
  end
  
  it "should be able to find a constant and some methods (fuzzy)" do
     APILookup.search("ActiveRecord::Base#nw").should eql([find_entry("ActiveRecord::Base", "new"), find_entry("ActiveRecord::Base", "new_record?")])
  end
  
  it "should be able to search on shortened constants" do
    APILookup.search("ar::base#new").should eql([find_entry("ActiveRecord::Base", "new")])
  end
  
end
