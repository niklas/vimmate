require File.dirname(__FILE__) + '/spec_helper'

#describe VimMate::ListedTree do
#  before(:each) do
#    @tree = VimMate::ListedTree.new
#  end
#
#  it "should be a ListedTree" do
#    @tree.should be_instance_of(VimMate::ListedTree)
#  end
#
#  describe "adding a single file" do
#    before(:each) do
#      @path = __FILE__
#      @mock_file = mock(ListedFile, :path => @path)
#      ListedFile.should_receive(:new).with(@path).once.and_return(@mock_file)
#      lambda do
#        @tree.add_path @path
#      end.should_not raise_error
#    end
#    it "should have a single file" do
#      @tree.paths_count.should == 1
#    end
#  end
#  describe "adding a single directory (mocked)" do
#    before(:each) do
#      @path = File.dirname __FILE__
#      @mock_directory = mock(ListedDirectory, :path => @path)
#      ListedDirectory.should_receive(:new).with(@path).once.and_return(@mock_directory)
#      lambda do
#        @tree.add_path @path
#      end.should_not raise_error
#    end
#    it "should have stored a single path" do
#      @tree.paths_count.should == 1
#    end
#  end
#  describe "adding a single directory (real)" do
#    before(:each) do
#      @path = File.dirname __FILE__
#      #ListedDirectory.should_receive(:new).with(@path).once
#      ListedFile.should_receive(:new).at_least(7).times
#      lambda do
#        @tree.add_path @path
#      end.should_not raise_error
#    end
#    it "should have stored a single path" do
#      @tree.paths_count.should >= 8
#    end
#  end
#  describe "adding multiple directories" do
#  end
#  describe "adding multiple files" do
#  end
#  describe "adding multiple files and directories" do
#  end
#end
