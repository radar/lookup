require File.dirname(__FILE__) + '/spec_helper'

describe "Lookup" do
  before do
    # So it outputs text for us.
    OPTIONS.merge!({ :text => true })
  end
  
  it "should be able to find a constant" do
    Lookup.do("ActiveRecord::Base")
  end
  
  it "should be able to find a constant and a method (using hash symbol)" do
    Lookup.do("ActiveRecord::Base#new")
  end
  
  it "should be able to find a constant and a method (using space)" do
    Lookup.do("ActiveRecord::Base new")
  end
  
  it "should be able to do a fuzzy match on the method" do
    Lookup.do("ActiveRecord::Base#destry")
  end
  
  it "should prompt the user to be more specific" do
    Lookup.do("be")
  end
  
  it "should be able to do a fuzzy match on the constant and method" do
    Lookup.do("AR::B#destroy")
  end
end
