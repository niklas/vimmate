require File.dirname(__FILE__) + '/spec_helper'

describe ListedDirectory do
  before(:each) do
    @filepath = File.dirname(__FILE__)
    @mock_tree_signal = lambda do
      # noop
    end
    @file = ListedDirectory.new(__FILE__,nil,&@mock_tree_signal)
  end
  it "should be a listed file" do
    @file.should be_instance_of(ListedDirectory)
  end

  it "should have an icon_type of folder" do
    @file.icon_type.should == :folder
  end
end

