require File.dirname(__FILE__) + '/spec_helper'

describe ListedFile do
  before(:each) do
    @path = File.expand_path(__FILE__)
    @mock_tree_signal = lambda do
      #noop
    end
    @iter = mock(:[] => 'value', :[]= => true)
    @file = ListedFile.new(:full_path => @path, :iter => iter_mock)
  end
  it "should be a listed file" do
    @file.should be_instance_of(ListedFile)
  end

  it "should have an icon_type of file" do
    pending "where is the icon_type?"
    @file.icon_type.should == :file
  end
end
