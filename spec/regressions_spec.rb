require File.dirname(__FILE__) + '/spec_helper'

describe "testing for regressions" do
  it "should not fail if an initial hash is specified" do
    lambda { Lookup.search("v2.3.8 #today?") }.should_not raise_error
  end
  
  it "must have an API specified" do
    lambda { Lookup.search("ActiveRecord::Base") }.should raise_error(Lookup::APINotFound)
  end
  
end