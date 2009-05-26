require File.dirname(__FILE__) + '/../spec_helper'

describe ListedDirectory do
  before(:each) do
    @files_count = 7
    @path = File.expand_path(File.dirname(__FILE__))

    @mock_tree_signal = mock("Tree")
    @mock_block = lambda do |*args|
      @mock_tree_signal.call(*args)
    end
    #@mock_tree_signal.should_receive(:call).with(:add,be_instance_of(VimMate::ListedDirectory)).once.ordered
    #@mock_tree_signal.should_receive(:call).with(:refresh,be_instance_of(VimMate::ListedDirectory)).once.ordered
    #@mock_tree_signal.should_receive(:call).with(:add,be_instance_of(VimMate::ListedFile)).at_least(@files_count).times.ordered

    @dir = ListedDirectory.new(:full_path => @path, :iter => iter_mock, :tree => tree_mock)
  end
  it "should be a listed file" do
    @dir.should be_instance_of(ListedDirectory)
  end

  it "should have an icon_type of folder" do
    pending "where it is gone?"
    @dir.icon_type.should == :folder
  end

  it "should have the path set" do
    pending "mock iter right"
    @dir.full_path.should == @path
  end

  it "should have some files in it" do
    pending "where is the count?"
    @dir.files_count.should == @files_count
  end
end

