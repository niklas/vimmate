require File.dirname(__FILE__) + '/../spec_helper'

describe ListedDirectory do
  before(:each) do
    @files_count = 7
    @path = File.expand_path(File.dirname(__FILE__))
    @dir = ListedDirectory.new(:full_path => @path)
  end
  it "should be a listed file" do
    @dir.should be_instance_of(ListedDirectory)
  end

  it "should have an icon_type of folder" do
    @dir.icon_name.should == "folder"
  end

  it "should have the path set" do
    @dir.full_path.should == @path
  end

  it "should have some files in it" do
    pending "where is the count?"
    @dir.files_count.should == @files_count
  end
end

