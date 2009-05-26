require File.dirname(__FILE__) + '/../spec_helper'

describe ListedFile do
  context "giving a file path" do
    before( :each ) do
      @path = File.expand_path(__FILE__)
    end
    before(:each) do
      @attrs = {
        :full_path => @path,
        :status => 'normal'
      }
      @file = ListedFile.create(@attrs)
    end
    it "should be recognized as a listed file" do
      @file.should be_a(ListedFile)
    end

    it "should save the given attributes" do
      @file.full_path.should == @path
      @file.name.should == 'listed_file_spec.rb'
    end

    it "should have an icon" do
      @file.icon.should_not be_nil
    end
  end

  context "giving a directory path" do
    before( :each ) do
      @path = File.dirname File.expand_path(__FILE__)
    end
    before(:each) do
      @attrs = {
        :full_path => @path,
        :status => 'normal'
      }
      @file = ListedFile.create(@attrs)
    end
    it "should be recognized as a listed directry" do
      @file.should be_a(ListedDirectory)
    end

    it "should save the given attributes" do
      @file.full_path.should == @path
      @file.name.should == 'lib'
    end

    it "should have an icon" do
      @file.icon.should_not be_nil
    end
  end
end
