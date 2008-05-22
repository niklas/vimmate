require File.dirname(__FILE__) + '/spec_helper'

describe ListedTree do
  before(:each) do
    @tree = ListedTree.new
  end

  it "should be a ListedTree" do
    @tree.should be_instance_of(ListedTree)
  end

  describe ", adding this spec directory (mocked)" do
    before(:each) do
      @path = File.dirname(__FILE__)
      @mock_directory = mock(ListedDirectory, :path => @path)
      ListedDirectory.should_receive(:new).with(@path,anything()).once.and_return(@mock_directory)
      lambda do
        @tree.add_path @path
      end.should_not raise_error
    end

    it "should iterate the spec directory" do
      @tree.each do |path|
        path.should == @mock_directory
      end
    end
  end

  describe ", adding this file (mocked)" do
    before(:each) do
      @path = __FILE__
      @mock_file = mock(ListedFile, :path => @path)
      ListedFile.should_receive(:new).with(@path).once.and_return(@mock_file)
      lambda do
        @tree.add_path @path
      end.should_not raise_error
    end

    it "should iterate the spec directory" do
      @tree.each do |path|
        path.should == @mock_file
      end
    end
  end
end
