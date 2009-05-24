require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWindow::ActiveTreeStore do
  before( :each ) do
    @ats = ActiveWindow::ActiveTreeStore
  end
  it "should inherit from Gtk::TreeStore" do
    @ats.should < Gtk::TreeStore
  end
  it "should store columns" do
    @ats.id.should_not be_nil
    @ats.id.should be_a(Hash)
  end

  it "should have basic columns" do
    @ats.id.should have_key(:visible)
    @ats.id.should have_key(:object)
  end

  it "should store column index in constants" do
    @ats::VISIBLE.should == 0
    @ats::OBJECT.should == 1
  end

  it "should provide classes for columns" do
    @ats.column_classes.should == [TrueClass, Object]
  end

  describe "subclassing for Person with name and age" do
    before( :each ) do
      class PersonTree < @ats
        column :name, String
        column :age, Fixnum
      end
    end

    it "should still have basic columns" do
      PersonTree.id.should have_key(:visible)
      PersonTree.id.should have_key(:object)
    end
    it "should have both new columns defined" do
      PersonTree.id.should have_key(:name)
      PersonTree.id.should have_key(:age)
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
    it "should provde classes for columns" do
      PersonTree.column_classes.should == [TrueClass, Object, String, Integer]
    end
    it "should store column index in hash" do
      PersonTree.id.should == {:visible => 0, :object => 1, :name => 2, :age => 3}
    end


    describe "instancing" do
      before( :each ) do
        @person_tree = PersonTree.new
      end
      
      describe "adding a Person" do
        before( :each ) do
          @person = mock(:name => 'Kate', :age => 23)
        end

        it "should succeed" do
          lambda { @person_tree.add @person }.should_not raise_error
        end
        
      end

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
      AppleTree.id[:visible].should == 0
      AppleTree.id[:object].should == 1
      LemonTree.id[:visible].should == 0
      LemonTree.id[:object].should == 1
    end
    it "should define columns for both subclasses" do
      AppleTree.id[:apple_count].should == 2
      LemonTree.id[:lemon_count].should == 2
    end
    it "should keep the new columns to their Classes" do
      AppleTree.id.should_not have_key(:lemon_count)
      LemonTree.id.should_not have_key(:apple_count)
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
    it "should provde classes for columns" do
      AppleTree.column_classes.should == [TrueClass, Object, Integer]
      LemonTree.column_classes.should == [TrueClass, Object, Integer]
    end
  end
end

