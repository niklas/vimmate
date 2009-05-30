require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWindow::ActiveTreeStore do
  before( :each ) do
    @ats = ActiveWindow::ActiveTreeStore
  end
  it "should inherit from Gtk::TreeStore" do
    @ats.should < Gtk::TreeStore
  end
  it "should store columns" do
    @ats.column_id.should_not be_nil
    @ats.column_id.should be_a(Hash)
  end

  it "should have basic columns" do
    @ats.column_id.should have_key(:visible)
    @ats.column_id.should have_key(:object)
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

    after( :each ) do
      Object::send :remove_const, :PersonTree
    end

    it "should still have basic columns" do
      PersonTree.column_id.should have_key(:visible)
      PersonTree.column_id.should have_key(:object)
    end
    it "should have both new columns defined" do
      PersonTree.column_id.should have_key(:name)
      PersonTree.column_id.should have_key(:age)
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
      PersonTree.column_id.should == {:visible => 0, :object => 1, :name => 2, :age => 3}
    end

    describe "with index on name" do
      before( :each ) do
        PersonTree.index_by :name
      end

      it "should define a method to remember People by name" do
        PersonTree.public_instance_methods.should include('remember_iter_by_name')
      end

      it "should define a method to find People by name" do
        PersonTree.public_instance_methods.should include('find_by_name')
      end

      describe "added Peter, Paul and Mary" do
        before( :each ) do
          @person_tree = PersonTree.new
          @person_tree.add :name => 'Peter', :age => 23
          @person_tree.add :name => 'Paul', :age => 42
          @person_tree.add :name => 'Mary', :age => 19
        end

        it "should have indexed the items" do
          @person_tree.index_by_name.should be_a(Hash)
          @person_tree.index_by_name.should have_key('Peter')
          @person_tree.index_by_name.should have_key('Paul')
          @person_tree.index_by_name.should have_key('Mary')
        end

        it "should index by Strings (the names)" do
          @person_tree.index_by_name.keys.each do |key|
            key.should be_a(String)
          end
        end

        it "should index TreeRowReferences" do
          @person_tree.index_by_name.values.each do |value|
            value.should be_a(Gtk::TreeRowReference)
          end
        end

        it "should find the row for Peter by its name" do
          peter = nil
          lambda { peter = @person_tree.find_by_name('Peter') }.should_not raise_error
          peter.should_not be_nil
          peter.should be_a(Gtk::TreeIter)
          peter[2].should == 'Peter'
        end
        
      end
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

    after( :each ) do
      Object::send :remove_const, :AppleTree
      Object::send :remove_const, :LemonTree
    end


    it "should both still have basic columns" do
      AppleTree.column_id[:visible].should == 0
      AppleTree.column_id[:object].should == 1
      LemonTree.column_id[:visible].should == 0
      LemonTree.column_id[:object].should == 1
    end
    it "should define columns for both subclasses" do
      AppleTree.column_id[:apple_count].should == 2
      LemonTree.column_id[:lemon_count].should == 2
    end
    it "should keep the new columns to their Classes" do
      AppleTree.column_id.should_not have_key(:lemon_count)
      LemonTree.column_id.should_not have_key(:apple_count)
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

  describe "Adding a column to a subclass" do
    before( :each ) do
      @sc = Class.new(@ats)
    end

    it "should return it to use it somewhere else" do
      col = @sc.column(:name, :string)
      col.should_not be_nil
      col.should be_a(ActiveWindow::ActiveColumn)
    end
  end
  
  describe "subclassing with a composite column with 2 subcolumns" do
    before( :each ) do
      class ComplexTree < @ats
        composite_column "Name and Age" do |pack|
          pack.add column(:name, :string)
          pack.add column(:age,  :integer)
        end
      end
    end

    after( :each ) do
      Object::send :remove_const, :ComplexTree
    end

    it "should create 3 columns" do
      ComplexTree.should have_at_least(3).columns
    end

    it "should have 2 invisible columns" do
      ComplexTree.should have_at_least(2).invisible_columns
    end

    it "should have max 1 visible column (the composite one)" do
      names = ComplexTree.visible_columns.map(&:name)
      names.should == ['Name and Age']
      ComplexTree.should have_at_most(1).visible_columns
      names.should include('Name and Age')
    end

    it "should have 2 data columns (the subs)" do
      ComplexTree.should have_at_least(2).data_columns
      names = ComplexTree.data_columns.map(&:name)
      names.should include('name')
      names.should include('age')
    end

    describe "creating a class filtering it" do
      before( :each ) do
        class FilteredComplexTree < ActiveWindow::FilteredActiveTreeStore
          def iter_visible?(iter)
            !( iter[ self.class.column_id[:name] ].index(filter_string) ).nil?
          end
        end
      end
      after( :each ) do
        Object::send :remove_const, :FilteredComplexTree
      end

      it "should take its columns from ComplexTree" do
        FilteredComplexTree.columns.should == ComplexTree.columns
      end

      describe "instancing it with a model" do
        before( :each ) do
          @tree = ComplexTree.new
          @filtered_tree = FilteredComplexTree.new @tree
        end

        describe "and filtering some data" do
          before( :each ) do
            @tree.add(:name => 'Niklas', :age => 27)
            @tree.add(:name => 'Grandpa', :age => 99)
            @filtering = lambda { @filtered_tree.filter = 'something' }
            @vis_col = 0
          end
          it "should not break on filtering" do
            @filtering.should_not raise_error
          end

          it "should check iter for visibility" do
            @filtered_tree.should_receive(:iter_visible?).at_least(:twice)
            @filtering.call
          end

          it "should hide rows that do not match" do
            @filtered_tree.stub(:iter_visible?).and_return(false)
            @filtering.call
            @tree.each do |model, path, iter|
              iter[@vis_col].should be_false
            end
          end

          it "should show rows that do match" do
            @filtered_tree.stub(:iter_visible?).and_return(true)
            @filtering.call
            @filtered_tree.found_count.should >= 2
            @tree.each do |model, path, iter|
              iter[@vis_col].should be_true
            end
          end
        end
        
      end
      
    end
    
  end
end

