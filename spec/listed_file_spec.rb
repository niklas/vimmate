require File.dirname(__FILE__) + '/spec_helper'

describe ListedFile do
  before(:each) do
    @path = File.expand_path(__FILE__)
    @mock_tree_signal = lambda do
      #noop
    end
    @file = ListedFile.new(@path,nil,&@mock_tree_signal)
  end
  it "should be a listed file" do
    @file.should be_instance_of(ListedFile)
  end

  it "should have an icon_type of file" do
    @file.icon_type.should == :file
  end
end
