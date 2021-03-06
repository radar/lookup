require File.dirname(__FILE__) + '/spec_helper'

describe "testing for regressions" do
  it "should not fail if an initial hash is specified" do
    lambda { Lookup.search("v2.3.8 #today?") }.should_not raise_error
  end
  
  it "must have an API specified" do
    lambda { Lookup.search("ActiveRecord::Base") }.should raise_error(Lookup::APINotFound)
  end
  
  it "must have a valid URL" do
    Lookup.search("1.9 Array#shuffle").first.url.scan("http").size.should eql(1)
  end

  it "must have an API specified for constant + method" do
    lambda { Lookup.search("String#=~") }.should raise_error(Lookup::APINotFound)
  end
end