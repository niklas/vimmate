require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWindow::ActiveTreeStore do
  before( :each ) do
    @ats = ActiveWindow::ActiveTreeStore
  end
  it "should inherit from Gtk::TreeStore" do
    @ats.should < Gtk::TreeStore
  end
  it "should store columns" do
    @ats.columns.should_not be_nil
    @ats.columns.should be_a(Hash)
  end

  it "should have basic columns" do
    @ats.columns.should have_key(:visible)
    @ats.columns.should have_key(:object)
  end

  it "should store column index in constants" do
    @ats::VISIBLE.should == 0
    @ats::OBJECT.should == 1
  end

  describe "subclassing with two columns" do
    before( :each ) do
      class PersonTree < @ats
        column :name, String
        column :age, Fixnum
      end
    end

    it "should still have basic columns" do
      PersonTree.columns.should have_key(:visible)
      PersonTree.columns.should have_key(:object)
    end
    it "should have both new columns defined" do
      PersonTree.columns.should have_key(:name)
      PersonTree.columns.should have_key(:age)
    end
    it "should have 4 columns" do
      PersonTree.column_count.should == 4
    end
    it "should store column index in constants" do
      PersonTree::VISIBLE.should == 0
      PersonTree::OBJECT.should == 1
      PersonTree::NAME.should == 2
      PersonTree::AGE.should == 3
    end
    it "should store column index in hash" do
      PersonTree.columns.should == {:visible => 0, :object => 1, :name => 2, :age => 3}
    end
  end

  describe "subclassing twice with different columns" do
    before( :each ) do
      class AppleTree < @ats
        column :apple_count, Fixnum
      end
      class LemonTree < @ats
        column :lemon_count, Fixnum
      end
    end

    it "should both still have basic columns" do
      AppleTree.columns[:visible].should == 0
      AppleTree.columns[:object].should == 1
      LemonTree.columns[:visible].should == 0
      LemonTree.columns[:object].should == 1
    end
    it "should define columns for both subclasses" do
      AppleTree.columns[:apple_count].should == 2
      LemonTree.columns[:lemon_count].should == 2
    end
    it "should keep the new columns to their Classes" do
      AppleTree.columns.should_not have_key(:lemon_count)
      LemonTree.columns.should_not have_key(:apple_count)
    end
    it "should both have 3 columns" do
      AppleTree.column_count.should == 3
      LemonTree.column_count.should == 3
    end
    it "should store first column index in constants" do
      AppleTree::VISIBLE.should == 0
      AppleTree::OBJECT.should == 1
      AppleTree::APPLE_COUNT.should == 2
    end
    it "should store second column index in constants" do
      LemonTree::VISIBLE.should == 0
      LemonTree::OBJECT.should == 1
      LemonTree::LEMON_COUNT.should == 2
    end
  end
end

