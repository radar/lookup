require File.dirname(__FILE__) + '/spec_helper'

describe "testing for regressions" do
  it "should not fail if an initial hash is specified" do
    lambda { APILookup.search("v2.3.8 #today?") }.should_not raise_error
  end
  
end