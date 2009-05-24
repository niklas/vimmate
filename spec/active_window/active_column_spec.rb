require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWindow::ActiveColumn do
  before( :each ) do
    @class = ActiveWindow::ActiveColumn
  end

  it "shold be a Class" do
    @class.should be_a(Class)
  end

  shared_examples_for "any column" do
    it "should be a ActiveColumn" do
      @col.should be_a(ActiveWindow::ActiveColumn)
    end

    it "should have a view" do
      @col.view.should_not be_nil
    end
    
  end

  describe "of type String" do
    before( :each ) do
      @col = @class.create(0,'name', :string)
    end
    it_should_behave_like 'any column'

    it "should be a ActiveTextColumn" do
      @col.should be_a(ActiveWindow::ActiveTextColumn)
    end

    it "should take a String" do
      @col.data_class.should == String
    end



  end
  
end
